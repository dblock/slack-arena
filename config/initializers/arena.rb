module Arena
  class Client
    def try_channel(name, options = {})
      Arena.channel(name, options)
    rescue Arena::Error => e
      case e.message
      when '404: Not Found - The resource you are looking for does not exist.'
        nil
      else
        raise e
      end
    end
  end
end