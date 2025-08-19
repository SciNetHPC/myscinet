
.PHONY: gettext
gettext:
	docker compose exec myscinet mix gettext.extract
	docker compose exec myscinet mix gettext.merge priv/gettext

.PHONY: format
format:
	docker compose exec myscinet mix format
