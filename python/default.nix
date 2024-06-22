{ config, pkgs, ...}:
{	home.packages = with pkgs; [
	  (python311.withPackages (
	  	ps:
			with ps; [
        # Typing
        mypy

			  # formatter
			  black

			  # other
			  virtualenv
        pip
			])
	)
  ];
}

