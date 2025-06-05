class Admin::CommentsController < ApplicationController
  before_action :authenticate_admin!
  layout 'admin'


  def index
    @comments = Comment.order(created_at: :desc) # 最新順にソート
  
    # 検索機能: `params[:query]` が存在する場合、コメント内容を検索
    if params[:query].present?
      @comments = @comments.where("content LIKE ?", "%#{params[:query]}%")
    end
  
    # 通報フィルター: `params[:reported_only]` が `true` の場合、通報済みコメントのみ取得
    if params[:reported_only] == "true"
      @comments = @comments.where(reported: true)
    end
  end

  def show
    @comment = Comment.find(params[:id])
  end

  def destroy
    @comment = Comment.find_by(id: params[:id])
  
    if @comment
      @comment.destroy
      redirect_to admin_comments_path, notice: "コメントを削除しました"
    else
      redirect_back fallback_location: admin_comments_path, alert: "コメントが見つかりませんでした"
    end
  end
  

  def unreport
    @comment = Comment.find(params[:id])
    
    if @comment.update(reported: false)
      redirect_to admin_comment_path(@comment), notice: "コメントの通報を解除しました"
    else
      redirect_to admin_comment_path(@comment), alert: "通報解除できませんでした"
    end
  end

  def search
    @comments = Comment.all
  
    # 通報されたコメントのみフィルタリング
    if params[:reported_only] == "true"
      @comments = @comments.where(reported: true)
    end
  
    # キーワード検索の処理
    if params[:query].present?
      @comments = @comments.where("content LIKE ?", "%#{params[:query]}%")
    end
  
    render :index # 既存の `index` ビューを再利用！
  end

end