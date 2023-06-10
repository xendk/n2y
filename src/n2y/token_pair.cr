module N2y
  class TokenPair
    getter! access : String?
    getter! refresh : String?

    def initialize(*, @access = nil, @refresh = nil)
    end

    def access=(@access : String?)
      if callback = @access_change
        callback.call(self)
      end

    end

    def on_access_change(&block : TokenPair ->)
      @access_change = block
    end

    def refresh=(@refresh : String?)
      if callback = @refresh_change
        callback.call(self)
      end

    end

    def on_refresh_change(&block : TokenPair ->)
      @refresh_change = block
    end

    # Invalidate access token.
    def invalidate_access
      # Using setter to trigger callback.
      self.access = nil
    end

    # Invalidate refresh token (also invalidates access).
    def invalidate_refresh
      self.access = nil
      self.refresh = nil
    end

    # Invalidate both tokens.
    def invalidate
      invalidate_refresh
    end

    def usable?
      @access || @refresh
    end
  end
end
