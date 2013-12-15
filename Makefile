publish:
	bundle exec ruhoh compile
	bundle exec ruhoh publish github

setup:
	git submodule update --init
	bundle install
