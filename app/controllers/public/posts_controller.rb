class Public::PostsController < ApplicationController

  def index
  end

  def new
    @post = Post.new
  end

  def create
    @post = current_user.posts.build(post_params)  #ログインユーザーの投稿として保存
    if @post.save
      redirect_to posts_path, notice: "投稿が完了しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @post = current_user.posts.find(params[:id])
  end

  def update
    @post = current_user.posts.find(params[:id])  #ログインユーザー以外の投稿を操作できないように制限
    if @post.update(post_params)
      redirect_to posts_path, notice: "投稿を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy
    redirect_to posts_path, notice: "投稿を削除しました"
  end

end



  private

  def post_params
    params.require(:post).permit(:title, :content)
  end
  
end
