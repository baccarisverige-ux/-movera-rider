/// Client code never holds payment/JWT/DB secrets.
abstract final class ClientSecrets {
  static const bool hasServerSecrets = false;
}
