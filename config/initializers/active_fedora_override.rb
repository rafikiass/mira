module ActiveFedora
  class << self
    attr_writer :data_production_credentials

    def data_production_credentials
      ActiveFedora.config unless @data_production_credentials.present?
      @data_production_credentials
    end
  end

  class Config
    # Override so that we use data_stage as the key rather than the top level if this is MIRA.
    def init_single(vals)
      ActiveFedora.data_production_credentials = vals.symbolize_keys[:data_production].symbolize_keys
      fedora_instance = :data_stage
      @credentials = vals.symbolize_keys[fedora_instance].symbolize_keys

      unless @credentials.has_key?(:user) && @credentials.has_key?(:password) && @credentials.has_key?(:url)
        raise ActiveFedora::ConfigurationError, "Fedora configuration must provide :user, :password and :url."
      end
    end
  end
end
