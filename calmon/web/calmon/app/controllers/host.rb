class Host < Application

  def index
    @hosts = Calmon::Models::Host.all
    render
  end

  def show
    @host = Calmon::Models::Host.get(params[:id])
    render
  end
  
end
