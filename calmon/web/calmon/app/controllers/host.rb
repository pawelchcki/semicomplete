class Host < Application

  def index
    @hosts = Calmon::Models::Host.all
    render
  end

  def show
    render
  end
  
end
