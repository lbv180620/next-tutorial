use todo_list;

drop table if exists todo_items;

create table if not exists todo_items (
	id int(11) auto_increment not null primary key comment 'ID',
	user_id int(11) not null comment 'ユーザID',
	item_name varchar(100) default null comment '項目名',
	registration_date date default null comment '登録日',
	expiration_date date default null comment '期限日',
	finished_date date default null comment '完了日',
	is_deleted tinyint(4) not null default 0 comment '削除フラグ',
	create_date_time datetime not null default current_timestamp comment '登録日時',
	update_date_time datetime not null default current_timestamp on update current_timestamp comment '更新日時'
)engine=InnoDB default charset=utf8mb4 collate=utf8mb4_general_ci comment='作業項目';

-- ALTER TABLE `todo_items`
--   ADD KEY `IX_todo_items_user_id` (`user_id`);

alter table todo_items add index ix_todo_items_user_id (user_id);
