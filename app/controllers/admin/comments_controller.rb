class Admin::CommentsController < ApplicationController
  before_action :authenticate_admin!

  def index
    @comments = Comment.order(created_at: :desc) # 最新のコメントを取得
  end

  def show
    @comment = Comment.find(params[:id])
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    redirect_to admin_comments_path, notice: "コメントを削除しました"
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
    @comments = Comment.where("content LIKE ?", "%#{params[:query]}%")
    render :index
  end

end