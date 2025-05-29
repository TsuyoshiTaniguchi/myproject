class Public::CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :restrict_guest_access, only: [:create, :report]


  def create
    post = Post.find(params[:post_id])
    comment = post.comments.new(comment_params)
    comment.user = current_user

    if comment.save
      redirect_to post_path(post), notice: "コメントを追加しました！"
    else
      redirect_to post_path(post), alert: "コメントの追加に失敗しました。"
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    if comment.user == current_user
      comment.destroy
      redirect_to post_path(comment.post), notice: "コメントを削除しました。"
    else
      redirect_to post_path(comment.post), alert: "削除できません。"
    end
  end

  def report
    @comment = Comment.find(params[:id])
    @comment.update(reported: true)
    redirect_to post_path(@comment.post), notice: "コメントを通報しました"
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end

  def restrict_guest_access
    if current_user.guest?
      flash[:alert] = "ゲストユーザーはこの操作を実行できません。"
      redirect_back(fallback_location: post_path(params[:post_id]))
    end
  end


end