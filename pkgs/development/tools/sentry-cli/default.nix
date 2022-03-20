{ rustPlatform
, fetchFromGitHub
, lib
, openssl
, pkg-config
, stdenv
, Security
, SystemConfiguration
}:
rustPlatform.buildRustPackage rec {
  pname = "sentry-cli";
  version = "1.73.1";

  src = fetchFromGitHub {
    owner = "getsentry";
    repo = "sentry-cli";
    rev = version;
    sha256 = "sha256-Er23OxFblRby9Vu4GvuPGJ4W0H/poRF5DbN1VXxHPJU=";
  };
  doCheck = false;

  # Needed to get openssl-sys to use pkgconfig.
  OPENSSL_NO_VENDOR = 1;

  buildInputs = [ openssl ] ++ lib.optionals stdenv.isDarwin [ Security SystemConfiguration ];
  nativeBuildInputs = [ pkg-config ];

  cargoSha256 = "sha256-gWE/rl7XsRjLq0PVVCpcIA9zwJknU8e3TXcj0gy40aI=";

  meta = with lib; {
    homepage = "https://docs.sentry.io/cli/";
    license = licenses.bsd3;
    description = "A command line utility to work with Sentry";
    changelog = "https://github.com/getsentry/sentry-cli/raw/${version}/CHANGELOG.md";
    maintainers = with maintainers; [ rizary ];
  };
}
