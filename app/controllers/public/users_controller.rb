class Public::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:edit, :update, :withdraw]

  def index
    # ログインユーザー、管理者、ゲストユーザーを除外
    @users = User.where.not(id: current_user.id)
                 .where.not(role: "admin")
                 .where.not(email: "guest@example.com")
    # @users が nil にならないように、何も該当しない場合は空のRelationになります
  end

  def mypage
    if current_user.nil?
      redirect_to new_user_session_path, alert: "ログインしてください。"
      return
    end
  
    @user = current_user
    following_ids = @user.following.pluck(:id)
    @daily_reports = DailyReport.where(user_id: current_user.id)
  
    # 投稿取得後、明示的に array に変換してフィルタリング
    posts = Post.where(user_id: following_ids)
                .where.not(user_id: @user.id)
                .order(created_at: :desc)
                .limit(10)
                .to_a
  
    @posts = filter_posts(posts)
    @joined_groups = @user.joined_groups
  
    # **GitHub データ取得を統合**
    if @user.github_username.present?
      github_service = GithubService.new(@user.github_username)
    
      @github_repos = Kaminari.paginate_array(github_service.fetch_repositories).page(params[:page]).per(6)
    
      # 🔹 各リポジトリの最新コミットを取得
      @recent_commits = @github_repos.flat_map do |repo|
        repo_full_name = "#{@user.github_username}/#{repo.name}" # 正しい形式でリポジトリ名を作成
        github_service.fetch_commits(repo_full_name) rescue [] # APIエラー時に処理を続行
      end.presence || []
    else
      @github_repos = Kaminari.paginate_array([]).page(params[:page]).per(6)
      @recent_commits = []
    end
  end


  def edit
    if current_user.guest?
      redirect_to users_mypage_path, alert: "ゲストユーザーはプロフィール編集できません。"
    else
      @user = current_user
    end
  end

  def update
    @user = current_user  # もしくは適切なユーザーの取得方法
    if @user.update(user_params)
      redirect_to user_path(@user), notice: "プロフィールが更新されました。"
    else
      render :edit, alert: "更新に失敗しました。"
    end
  end
  

  def show
    @user = User.find(params[:id])
    @following_users = @user.following
  
    # 投稿のフィルタリング
    own_posts = filter_posts(@user.posts.to_a)
    followed_user_ids = current_user.following.pluck(:id)
    followed_posts = filter_posts(Post.where(user_id: followed_user_ids).to_a)
    @posts = (own_posts + followed_posts).sort_by(&:created_at).reverse
  
    # GitHub APIの処理を `GithubService` に委譲
    if @user.github_username.present?
      github_service = GithubService.new(@user.github_username)
      @github_repos = Kaminari.paginate_array(github_service.fetch_repositories).page(params[:page]).per(6)
  
      # コミット履歴を取得し、カレンダー用データに変換
      @github_commits = @github_repos.flat_map do |repo|
        github_service.fetch_commits(repo.name).map do |commit|
          {
            title: commit[:title],
            start: commit[:date],
            url: commit[:url],
            backgroundColor: language_color(repo.language) # ✅ 言語ごとに色付け
          }
        end
      end
    else
      @github_repos = []
      @github_commits = []
    end
  end
  
  # 言語ごとの色を設定
  def language_color(language)
    colors = {
      "Ruby" => "#CC342D",
      "JavaScript" => "#F7DF1E",
      "Python" => "#3572A5",
      "Java" => "#B07219",
      "C++" => "#00599C",
      "不明" => "#CCCCCC"
    }
    colors[language] || "#66ccff"
  end
  

  # 退会確認
  def confirm_withdraw
    # ログインしているユーザー本人のデータMore actions
    @user = current_user
  end


  def withdraw
    if current_user.guest?
      redirect_to users_mypage_path, alert: "ゲストユーザーは退会できません。"
    else
      current_user.withdraw!
      reset_session
      redirect_to root_path, notice: "退会しました"
    end
  end

  def followed_posts
    user = User.find(params[:id]) # 指定されたユーザーを取得
    @posts = Post.where(user_id: user.connected_users.pluck(:id)) # フォローしているユーザーの投稿を取得
  end

  def search
    @query = params[:query]
    @users = User.where("name LIKE ?", "%#{@query}%")
    render :index
  end

  def report
    @user = User.find(params[:id])
    @user.update(reported: true) #  ユーザーを「通報済み」にする
    redirect_to user_path(@user), notice: "このユーザーを通報しました。"
  end

  def daily_reports
    @daily_reports = DailyReport.where(user_id: params[:id])
  
    respond_to do |format|
      format.html
      format.json do
        render json: @daily_reports.map do |report|
          {
            title: report.title,
            start: report.date.iso8601,
            description: report.content,
            user: report.user.name
          }
        end  # JSONのレスポンスにdescriptionやuserを含め、拡張性を確保
      end    # フロントエンド側でより多くの情報が扱えるように
    end
  end
  
  private

  # ここで、投稿がグループ投稿の場合にフィルタする
  # もし投稿の group が存在し、かつそのグループの privacy が "restricted_visibility" で、
  # 現在のユーザーがそのグループのメンバーでない場合、その投稿を除外。
  def filter_posts(posts)
    posts.reject do |post|
      post.group.present? &&
        post.group.restricted_visibility? &&
        !post.group.users.include?(current_user)
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :personal_statement, :portfolio_url, :portfolio_file, :profile_image)
  end

  def ensure_guest_user
    @user = User.find(params[:id])
    if @user.guest_user?
      redirect_to user_path(current_user), notice: "ゲストユーザーはプロフィール編集画面へ遷移できません。"
    end
  end

  def restrict_guest_access
    if current_user.guest?
      flash[:alert] = "ゲストユーザーはこの操作を実行できません。"
      redirect_to users_mypage_path
    end
  end

end




