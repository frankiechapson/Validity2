 
/*

    Demo for validity handling in case of joined tables

    ERD:   D ->  A  <-  B  <- C

*/

/*============================================================================================*/
/* INIT                                                                                       */
/*============================================================================================*/

drop table A; 
drop table B;
drop table C;
drop table D;

/*============================================================================================*/
/* TABLES for DEMO                                                                            */
/*============================================================================================*/

create table A (
     ID         number             not null
   , TEXT       varchar2( 100 )    not null
   , VFD        date     
   , VTD        date     
    );

/*============================================================================================*/

create table B (
     ID         number             not null
   , TEXT       varchar2( 100 )    not null
   , A_ID       number
   , VFD        date     
   , VTD        date     
    );

/*============================================================================================*/


create table D (
     ID         number             not null
   , TEXT       varchar2( 100 )    not null
   , A_ID       number
   , VFD        date     
   , VTD        date     
    );

/*============================================================================================*/

create table C (
     ID         number             not null
   , TEXT       varchar2( 100 )    not null
   , B_ID       number
   , VFD        date     
   , VTD        date     
    );

/*============================================================================================*/
/* TABLE VALUES for DEMO                                                                      */
/*============================================================================================*/

insert into A values ( 1, 'A1',    to_date( '1111.11.11','yyyy.mm.dd') , to_date( '2000.01.03','yyyy.mm.dd') );
insert into A values ( 2, 'A2',    to_date( '2000.02.11','yyyy.mm.dd') , to_date( '2000.03.01','yyyy.mm.dd') );
insert into A values ( 2, 'A2',    to_date( '2000.03.01','yyyy.mm.dd') , to_date( '2000.10.30','yyyy.mm.dd') );
insert into A values ( 2, 'A2',    to_date( '2000.10.30','yyyy.mm.dd') , to_date( '9999.01.01','yyyy.mm.dd') );

insert into B values ( 1, 'B1', 1, to_date( '2000.01.01','yyyy.mm.dd') , to_date( '9999.01.01','yyyy.mm.dd') );
insert into B values ( 2, 'B2', 1, to_date( '2000.01.02','yyyy.mm.dd') , to_date( '2000.01.05','yyyy.mm.dd') );
insert into B values ( 2, 'B2', 2, to_date( '2000.01.05','yyyy.mm.dd') , to_date( '9999.01.01','yyyy.mm.dd') );

insert into C values ( 1, 'C1', 1, to_date( '2000.01.03','yyyy.mm.dd') , to_date( '9999.01.01','yyyy.mm.dd') );
insert into C values ( 2, 'C2', 1, to_date( '2000.01.01','yyyy.mm.dd') , to_date( '2000.01.02','yyyy.mm.dd') );
insert into C values ( 3, 'C3', 2, to_date( '2000.05.07','yyyy.mm.dd') , to_date( '9999.01.01','yyyy.mm.dd') );

insert into D values ( 1, 'D1', 2, to_date( '2000.07.07','yyyy.mm.dd') , to_date( '9999.01.01','yyyy.mm.dd') );
insert into D values ( 2, 'D2', 2, to_date( '2000.02.02','yyyy.mm.dd') , to_date( '2000.10.10','yyyy.mm.dd') );

commit;

/*============================================================================================*/
/* Take every RELEVANT vfd, vtd from every RELEVANT table                                     */
/*============================================================================================*/

create or replace view DEMO_DATE_VW as 
select A.VFD    as  AVFD
     , A.VTD    as  AVTD
     , B.VFD    as  BVFD
     , B.VTD    as  BVTD
     , C.VFD    as  CVFD
     , C.VTD    as  CVTD
     , D.VFD    as  DVFD
     , D.VTD    as  DVTD
  from A
inner join B on ( B.A_ID = A.ID )
inner join D on ( D.A_ID = A.ID )
inner join C on ( C.B_ID = B.ID )
;

/*============================================================================================*/
/* Create rows from them and deduplicate them  ( all datum )                                  */
/*============================================================================================*/

create or replace view DEMO_DS_VW as 
with DS as ( select * from DEMO_DATE_VW )
select AVFD as DSD from DS union
select AVTD as DSD from DS union
select BVFD as DSD from DS union
select BVTD as DSD from DS union
select DVFD as DSD from DS union
select DVTD as DSD from DS union
select CVFD as DSD from DS union
select CVTD as DSD from DS
;

/*============================================================================================*/
/* Create date intervals/periods from them   ( all intervals )                                */
/*============================================================================================*/

create or replace view DEMO_DSP_VW as
select DSD                                                                       as VFD
     , lead( DSD, 1, to_date( '9999.01.01','yyyy.mm.dd') ) over ( order by DSD ) as VTD
  from DEMO_DS_VW
  where DSD < to_date( '9999.01.01','yyyy.mm.dd')
;

/*============================================================================================*/
/* Join the date intervals with the tables ( overlappings )                                   */
/*============================================================================================*/

create or replace view DEMO_ABCDP_VW as
select A.ID         as AID
     , A.TEXT       as ATEXT
     , B.ID         as BID
     , B.TEXT       as BTEXT
     , C.ID         as CID
     , C.TEXT       as CTEXT
     , D.ID         as DID
     , D.TEXT       as DTEXT
     , DSP.VFD      as VFD
     , DSP.VTD      as VTD
 from      DEMO_DSP_VW DSP
inner join A on (                   A.VFD < DSP.VTD and DSP.VFD < A.VTD )
inner join B on ( B.A_ID = A.ID and B.VFD < DSP.VTD and DSP.VFD < B.VTD )
inner join D on ( D.A_ID = A.ID and D.VFD < DSP.VTD and DSP.VFD < D.VTD )
inner join C on ( C.B_ID = B.ID and C.VFD < DSP.VTD and DSP.VFD < C.VTD )
;

/*============================================================================================*/
/* Create one interval from the continuous parts ( simplification )                           */
/*============================================================================================*/

create or replace view DEMO_ABCD_VW as
select S.AID
     , S.ATEXT
     , S.BID
     , S.BTEXT
     , S.CID
     , S.CTEXT
     , S.DID
     , S.DTEXT
     , min( S.VFD ) as VFD
     , max( E.VTD ) as VTD
  from     DEMO_ABCDP_VW S
 left join DEMO_ABCDP_VW E on ( S.VTD   = E.VFD 
                            and S.AID   = E.AID
                            and S.ATEXT = E.ATEXT
                            and S.BID   = E.BID
                            and S.BTEXT = E.BTEXT
                            and S.CID   = E.CID
                            and S.CTEXT = E.CTEXT
                            and S.DID   = E.DID
                            and S.DTEXT = E.DTEXT
                              )
group by S.AID
     , S.ATEXT
     , S.BID
     , S.BTEXT
     , S.CID
     , S.CTEXT
     , S.DID
     , S.DTEXT
;

/*============================================================================================*/
/* Play with the results                                                                      */
/*============================================================================================*/

select * from DEMO_DATE_VW;

select * from DEMO_DS_VW    order by DSD;

select * from DEMO_DSP_VW   order by VFD;

select * from DEMO_ABCDP_VW order by AID, VFD;

select * from DEMO_ABCD_VW  order by AID, VFD;

/*============================================================================================*/
