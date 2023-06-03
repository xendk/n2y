# Exceptions thrown by the Nordigen client.

module N2y
  class Nordigen
    abstract class AuthException < Exception
    end

    class InvalidAccessToken < AuthException
      def initialize
        super "Access denied"
      end
    end

    class InvalidRefreshToken < AuthException
      def initialize
        super "Invalid or expired refresh token"
      end
    end

    class InvalidCreds < AuthException
      def initialize
        super "Invalid secret_id/secret"
      end
    end
  end
end
