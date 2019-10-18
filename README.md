# How to manage data validity in case of joined tables

That is a normal thing to use validity in tables. For example a people can be member of different teams in different periods and can have different positions in different periods and can work on different projects on different periods etc.
Each table, MEMBERSHIPS, PERSON_POSITIONS, PROJECT_MEMBERS has a VALID_FROM_DATE (VFD) and a VALID_TO_DATE (VTD)
These VFD-VTD periods are indepent from each others:

    memberships  +------------------------+--------------+-------------------------------+---------------------------------------------------+
    positions           +----------------------+--------------------------------------------+-----------+-----------------------------+
    projects        +----------------+-------------------------------+-----------+-----------------------------+--------------------------------+


It is not a big challange if we would like to now the current team, position and project of a person in a certain day, but that is not so easy if we would like to create view from these data.

first of all, we have to collect all VFD and VTD date when something happened:

    all date     +  +   +            +    +    +         +           +           +       +  +           +      +                      +      +  +

then we have to create new VFD-VTD periods for them:

                 +--+---+------------+----+----+---------+-----------+-----------+-------+--+-----------+------+----------------------+------+--+

The if we join the PERSON, MEMBERSHIPS, PERSON_POSITIONS, PROJECT_MEMBERS tables with ID-s and with this new PERIODS with overlappings the table VFD-VTD and PERIOD VFD-VTD, then we will get result for each new period.

     all table   +--+---+------------+----+----+---------+-----------+-----------+-------+--+-----------+------+----------------------+------+--+

At last we have to merge the continuous periods. Two period are continuous if one follows the other and every attributes are identical. So, we can reduce the number of intervals.

Not so easy, and not too fast, but is is working.

### See the sql files for a demo!

