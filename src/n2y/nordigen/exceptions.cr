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

    class ConnectionError < Exception
      def initalize
        super "Institution service unavailable"
      end
    end

    class EUAExpiredError < Exception
      def initialize
        super "End user agreement expired"
      end
    end

    class SuspendedError < Exception
      def initialize
        super "Account or requisition was suspended"
      end
    end
  end
end
