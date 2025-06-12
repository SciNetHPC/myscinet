
gettext:
	docker compose exec myscinet mix gettext.extract
	docker compose exec myscinet mix gettext.merge priv/gettext
