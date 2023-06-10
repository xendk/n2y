module N2y
  class TokenPair
    getter! access : String?
    getter! refresh : String?

    @on_change : Nil | (TokenPair ->)

    def initialize(*, @access = nil, @refresh = nil)
      @on_change = nil
    end

    def initialize(*, @access = nil, @refresh = nil, &@on_change : TokenPair ->)
    end

    protected def on_change
      if callback = @on_change
        callback.call(self)
      end
    end

    def access=(@access : String?)
      on_change
    end

    def on_change(&@on_change : TokenPair ->)
    end

    def refresh=(@refresh : String?)
      on_change
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
