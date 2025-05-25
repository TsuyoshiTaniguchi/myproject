def create
  post = Post.find(params[:post_id])
  like = post.likes.new(user: current_user)

  if like.save
    redirect_to posts_path, notice: "いいねしました！"
  else
    redirect_to posts_path, alert: "いいねできませんでした。"
  end
end