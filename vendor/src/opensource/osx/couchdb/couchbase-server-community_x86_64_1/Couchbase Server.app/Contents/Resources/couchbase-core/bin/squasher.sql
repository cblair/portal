attach database "__SQUASHED_DATABASE__" as squashed;
begin;
create table if not exists squashed.cpoint_op
  (vbucket_id integer, cpoint_id integer, seq integer, op text,
   key varchar(250), flg integer, exp integer, cas integer, val blob,
   primary key(vbucket_id, key));
create table if not exists squashed.cpoint_state
  (vbucket_id integer, cpoint_id integer, prev_cpoint_id integer, state varchar(1),
   source varchar(250), updated_at text);
commit;

attach database "__INCREMENTAL_DATABASE__" as next;
begin;
create table if not exists next.cpoint_op
  (vbucket_id integer, cpoint_id integer, seq integer, op text,
   key varchar(250), flg integer, exp integer, cas integer, val blob,
   primary key(vbucket_id, key));
create table if not exists next.cpoint_state
  (vbucket_id integer, cpoint_id integer, prev_cpoint_id integer, state varchar(1),
   source varchar(250), updated_at text);
commit;

insert or ignore into squashed.cpoint_state(vbucket_id, cpoint_id, prev_cpoint_id, state, source, updated_at)
select vbucket_id, cpoint_id, prev_cpoint_id, state, source, updated_at
from next.cpoint_state
where next.cpoint_state.state = "closed";

insert or ignore into squashed.cpoint_op(vbucket_id,cpoint_id,seq,op,key,flg,exp,cas,val)
select cpoint_op.vbucket_id,cpoint_op.cpoint_id,seq,op,key,flg,exp,cas,val
from next.cpoint_state
  join next.cpoint_op on (cpoint_op.vbucket_id = cpoint_state.vbucket_id and
                     cpoint_op.cpoint_id = cpoint_state.cpoint_id)
where cpoint_state.state = "closed"
order by cpoint_op.cpoint_id desc;


