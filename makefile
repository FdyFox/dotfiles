# Makefile in ~/.dotfiles

# Default script
BOOTSTRAP := ./bootstrap.sh

.PHONY: all work server update run-gnome run-hyprland help

all:
	$(BOOTSTRAP)

work:
	$(BOOTSTRAP) --work

server:
	$(BOOTSTRAP) --server

install_hyperland:
	@echo "Running Hyprland setup"
	$(BOOTSTRAP) --file applications/15_hyprland_install.sh

install_kde:
	@echo "Running KDE setup"
	$(BOOTSTRAP) --file applications/15_kde_plasma_install.sh


help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  all                 Run full bootstrap"
	@echo "  work                Run work setup"
	@echo "  server              Run minimal setup for remote servers"
	@echo "  install_hyprland    Run Hyprland-specific setup"
	@echo "  install_kde         Run KDE-specific setup"

