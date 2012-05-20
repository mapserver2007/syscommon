# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # Plugin include
  include AuthenticatedSystem

  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '80d6cf63b9bca9c50b71e32d2adc9917'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  # filter_parameter_logging :password

  # Read common configuration

  protected

  # 共通設定
  def common_config
    # 環境設定
    config = YAML.load_file("config/tcliper.yml")

    # モード設定
    env_config = env_config(config["mode"])

    # ドキュメントルート
    @doc_root = config["mode"] == "production" ? "/tcliper/" : "/"

    # Clipの表示数
    @per_page = config["per_page"]

    # title
    @title = 'Tcliper@Ruby on Rails'

    # stylesheet
    @path_to_css = {
      "common" => env_config["path_to_syscommon"]["url"],
      "public" => env_config["path_to_css"]
    }

    # javascripts
    @path_to_js = env_config["path_to_js"]

    # javascripts library
    @path_to_lib = env_config["path_to_lib"]

    # images
    @path_to_img = env_config["path_to_img"]

    # header_menu
    @menu = YAML.load_file(env_config["path_to_syscommon"]["path"] + "common.yml")

    # Livedoor auth parameter
    @app_key = config["app_key"]
    @secret  = config["secret"]

  end

  # 例外処理
  def rescue_action_in_public(exception = nil)
    case exception
    when ActiveRecord::RecordNotFound, ::ActionController::UnknownAction, ::ActionController::RoutingError, ActionView::TemplateError, NoMethodError
      @error_title = "404 Page Not Found"
      @error_description = "存在しないページです。正しいページを指定してください。"
    else
      @error_title = "500 Server Internal Error"
      @error_description = "エラーが発生しました。管理者に問い合わせてください。"
    end
    render :template => 'shared/error'
  end

  private

  # 環境設定
  def env_config(mode = "production")
    # productionでは静的ファイルはApache経由で読ませる
    static_root = "/tcliper/public"

    env = {
      # 本番環境設定
      "production" => {
        "path_to_js"  => static_root + "/javascripts/",
        "path_to_lib" => static_root + "/javascripts/lib/",
        "path_to_css" => static_root + "/stylesheets/",
        "path_to_img" => static_root + "/images/",
        "path_to_syscommon" => {
          "url"  => "http://summer-lights.dyndns.ws/syscommon/",
          "path" => "/usr/local/apache2/htdocs/syscommon/"
        }
      },
      # 開発環境設定
      "development" => {
        "path_to_js"  => "/javascripts/",
        "path_to_lib" => "/javascripts/lib/",
        "path_to_css" => "/stylesheets/",
        "path_to_img" => "/images/",
        "path_to_syscommon" => {
          "url"  => "http://summer-lights.dyndns.ws/syscommon/",
          "path" => "C:/workspace/syscommon/"
        }
      }
    }

    return env[mode];
  end
end
