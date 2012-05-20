class TcliperController < ApplicationController
  layout 'base'
  before_filter :common_config

  STATUS_SUCCESS = "success"
  AUTH_TOKEN = '80d6cf63b9bca9c50b71e32d2adc9917'

  # 初期画面
  def index
    # Clipデータを取得
    @clip = Clip.paginate(
      :page => params[:page],
      :conditions => {:public => 1},
      :order => "date DESC",
      :per_page => @per_page,
      :include => :user
    )
    render :action => 'index'
  end

  # コメント編集
  def edit
    # Clipコメントを更新
    Clip.update(params[:id], :comment => params[:comment])
    render :text => {
      :id => params[:id],
      :comment => params[:comment],
      :status => STATUS_SUCCESS
    }.to_json
  end

  def authback
    if params[:auth_token] == AUTH_TOKEN
      livedoor_auth = Auth.new(
        :app_key => @app_key,
        :secret  => @secret
      )
      request = {
        :id => livedoor_auth.livedoor_id(params),
        :authenticity_token => form_authenticity_token
      }
      ttt = livedoor_auth.auto_signup(request)
      #livedoor_auth.auto_singup(livedoor_auth.livedoor_id(params))
      flash[:notice] = ttt.host.to_s + "/" + ttt.path.to_s + "/" + ttt.query.to_s
      redirect_back_or_default(@doc_root)
    end
  end
end
