let
  pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-12-22.tar.gz") {};

  # Build lbkeyboard from GitHub for vignette building
  lbkeyboard = pkgs.rPackages.buildRPackage {
    name = "lbkeyboard";
    src = fetchTarball {
      url = "https://github.com/b-rodrigues/lbkeyboard/archive/4d6eb48cc0558312e0099500f213a8f3a159b547.tar.gz";
    };
    propagatedBuildInputs = builtins.attrValues {
      inherit (pkgs.rPackages)
        dplyr
        GA
        ggplot2
        magrittr
        purrr
        Rcpp
        scales
        stringr
        ggforce
        prismatic
        tibble;
    };
  };

  # Package dependencies from DESCRIPTION
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages)
      # Direct dependencies (Imports)
      dplyr
      GA
      ggplot2
      magrittr
      purrr
      Rcpp
      scales
      stringr
      # Additional dependencies used in code
      ggforce
      prismatic
      tibble
      # Development tools
      devtools
      codetools
      knitr
      rmarkdown
      roxygen2
      pkgdown
      testthat
      usethis
      ;
  };

  system_packages = builtins.attrValues {
    inherit (pkgs)
      glibcLocales
      glibcLocalesUtf8
      nix
      pandoc
      R;
  };

in

pkgs.mkShell {
  LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
  LC_ALL = "en_US.UTF-8";
  LC_TIME = "en_US.UTF-8";
  LC_MONETARY = "en_US.UTF-8";
  LC_PAPER = "en_US.UTF-8";
  LC_MEASUREMENT = "en_US.UTF-8";

  buildInputs = [ rpkgs system_packages lbkeyboard ];

  shellHook = ''
    echo "lbkeyboard development environment"
    echo "Run 'devtools::load_all()' to load the package"
    echo "Run 'devtools::document()' to regenerate documentation"
    echo "Run 'devtools::check()' to run R CMD check"
  '';
}
