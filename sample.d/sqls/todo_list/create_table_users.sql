use todo_list;

drop table if exists users;

create table if not exists users (
	id int(11) auto_increment not null primary key comment 'ID',
	user_name varchar(50) not null comment 'ログインユーザ名',
	email varchar(255) not null unique comment 'メールアドレス',
	password varchar(255) not null comment 'ログインパスワード',
	family_name varchar(50) not null comment 'ユーザ姓',
	first_name varchar(50) not null comment 'ユーザ名',
	is_admin tinyint(4) not null default 0 comment '管理者権限',
	is_deleted tinyint(4) not null default 0 comment '削除フラグ',
	create_date_time datetime not null default current_timestamp comment '登録日',
	update_date_time datetime not null default current_timestamp on update current_timestamp comment '更新日時'
)engine=InnoDB default charset=utf8mb4 collate=utf8mb4_general_ci comment='ユーザ';
