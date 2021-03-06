class PostsController < ApplicationController
  before_action :authenticate
  before_action :site_owner, :only => [:submit]
  protect_from_forgery :except => [:create]

  def index
    @site = params[:site]
    if user_signed_in?
      @owns = current_user.owns_this_site("#{@site}.com")
    else
      @owns = false
    end
    @posts = Post.by_site(@site).page(params[:page] || 1).per(20)
    @grouped_posts = Post.group(@posts)
    @post_count = {}
    @grouped_posts.each do |group|
      @post_count[group[0]] = Post.in_month(group[0], @site).count
    end
  end

  def create
    @post = Post.fetch_and_create params[:url], current_user
    render json: { id: @post.id }
  end

  def submit

  end

  def show
    @post = Post.find(params[:id])
    @site = @post.domain.gsub(".com", "")
    if user_signed_in?
      @comment = Comment.post_comment_for_user(params[:id], current_user.id)
      if current_user.politburo?
        @total_comments = current_user.comments_for_month(@site, @post.month_and_year)
        @total_posts = Post.in_month(@post.month_and_year, @site).count
      end
    end
  end

  def preview
    @post = Post.find(params[:id])
  end

  def next
    @post = Post.by_site(params[:site]).next(params[:publish_time])
    if @post.nil?
      redirect_to site_path(params[:site])
    else
      redirect_to @post
    end
  end

  def prev
    @post = Post.by_site(params[:site]).prev(params[:publish_time])
    if @post.nil?
      redirect_to site_path(params[:site])
    else
      redirect_to @post
    end
  end

  def destroy
    post = Post.find(params[:id]).destroy
    render json: {
      success: true,
      post_id: params[:id],
      month_and_year: post.month_and_year.parameterize
    }
  end

  protected
  def site_owner
    flash[:notice] = "Only site leads can submit new stories. If you're a site lead and you're getting this message, ping Adam on Slack."
    domain = params["url"].match(/https?:\/\/(\w+\.)?(\w+\.com)/)[2]
    redirect_to root_path unless Permissions.site_owner?(current_user, domain)
  end

  def authenticate
    params[:api_key] == ENV["API_KEY"] || authenticate_user!
  end
end
