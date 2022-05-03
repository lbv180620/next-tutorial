# ==== PHPUnit関連 ====

pu-v:
	./vendor/bin/phpunit --version


# m phpunit dir=public/phpunit/tests
phpunit:
	./vendor/bin/phpunit $(dir) --colors

pu:
	@make phpunit

pu-d:
	./vendor/bin/phpunit $(dir) --colors --debug

pu-ts:
	./vendor/bin/phpunit --testsuite $(name)

# --filter <テストメソッド名>@<パラメータのパターン名>
pu-ts-f:
	./vendor/bin/phpunit --testsuite $(name) --filter $(method)

pu-ls:
	./vendor/bin/phpunit --list-suite

# ==== Composer関連 ====
dump-autoload:
	composer dump-autoload
