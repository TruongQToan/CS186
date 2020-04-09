DROP VIEW IF EXISTS q0, q1i, q1ii, q1iii, q1iv, q2i, q2ii, q2iii, q3i, q3ii, q3iii, q4i, q4ii, q4iii, q4iv, q4v;

-- Question 0
CREATE VIEW q0(era)
AS
SELECT MAX(era)
FROM pitching;
;

-- Question 1i
CREATE VIEW q1i(namefirst, namelast, birthyear)
AS
SELECT namefirst, namelast, birthyear
FROM people
WHERE weight > 300
;

-- Question 1ii
CREATE VIEW q1ii(namefirst, namelast, birthyear)
AS
SELECT namefirst, namelast, birthyear
FROM people
WHERE namefirst LIKE '% %'
;

-- Question 1iii
CREATE VIEW q1iii(birthyear, avgheight, count)
AS
SELECT birthyear, avg(height) as avgheight, count(*) AS count
FROM people
GROUP BY birthyear
ORDER BY birthyear
;

-- Question 1iv
CREATE VIEW q1iv(birthyear, avgheight, count)
AS
SELECT birthyear, avg(height) as avgheight, count(*) AS count
FROM people
GROUP BY birthyear
HAVING avg(height) > 70
ORDER BY birthyear
;

-- Question 2i
CREATE VIEW q2i(namefirst, namelast, playerid, yearid)
AS
SELECT namefirst, namelast, playerid, yearid
FROM people
         NATURAL JOIN halloffame
WHERE inducted = 'Y'
ORDER BY yearid desc;
;

-- Question 2ii
CREATE VIEW q2ii(namefirst, namelast, playerid, schoolid, yearid)
AS
SELECT namefirst, namelast, people.playerid, schools.schoolid, halloffame.yearid
FROM people,
     (SELECT playerid, yearid FROM halloffame WHERE inducted = 'Y') as halloffame,
     (SELECT schoolid FROM schools WHERE schoolstate = 'CA') as schools,
     collegeplaying
WHERE people.playerid = halloffame.playerid
  AND people.playerid = collegeplaying.playerid
  AND schools.schoolid = collegeplaying.schoolid
ORDER BY halloffame.yearid desc, schools.schoolid, people.playerid asc;
;

-- Question 2iii
CREATE VIEW q2iii(playerid, namefirst, namelast, schoolid)
AS
SELECT p.playerid, namefirst, namelast, schoolid
from (SELECT playerid, namefirst, namelast
      FROM people
               NATURAL JOIN halloffame
      WHERE inducted = 'Y') as p
         LEFT JOIN collegeplaying ON p.playerid = collegeplaying.playerid
order by playerid desc, schoolid
;

-- Question 3i
CREATE VIEW q3i(playerid, namefirst, namelast, yearid, slg)
AS
SELECT playerid,
       namefirst,
       namelast,
       yearid,
       trim(trailing '00' from round((h - h2b - h3b - hr + 2.0 * h2b + 3.0 * h3b + 4.0 * hr) / ab, 15)::text)::numeric AS slg
FROM people
         NATURAL JOIN (SELECT * FROM batting WHERE ab > 50) AS bat
ORDER BY slg DESC, yearid, playerid
LIMIT 10;
;

-- Question 3ii
CREATE VIEW q3ii(playerid, namefirst, namelast, lslg)
AS
SELECT playerid,
       namefirst,
       namelast,
       trim(trailing '00' from round((b.h - b.h2b - b.h3b - b.hr + 2.0 * b.h2b + 3.0 * b.h3b + 4.0 * b.hr) / b.ab, 15)::text)::numeric AS lslg
FROM people
         natural join
     (select playerid, sum(h) as h, sum(h2b) as h2b, sum(h3b) as h3b, sum(hr) as hr, sum(ab) as ab
      from batting
      group by playerid
      having sum(ab) > 50) as b
order by lslg desc, playerid
limit 10
;

-- Question 3iii
CREATE VIEW q3iii(namefirst, namelast, lslg)
AS
SELECT namefirst, namelast, trim(trailing '0' from round(slg, 15)::text)::numeric AS lslg
FROM people
         natural join
     (select playerid,
             ((sum(h) - sum(h2b) - sum(h3b) - sum(hr) + 2.0 * sum(h2b) + 3.0 * sum(h3b) + 4.0 * sum(hr)) /
              sum(ab)) as slg
      from batting
      group by playerid
      having sum(ab) > 50
         and ((sum(h) - sum(h2b) - sum(h3b) - sum(hr) + 2.0 * sum(h2b) + 3.0 * sum(h3b) + 4.0 * sum(hr)) / sum(ab)) >
             (select ((sum(h) - sum(h2b) - sum(h3b) - sum(hr) + 2.0 * sum(h2b) + 3.0 * sum(h3b) + 4.0 * sum(hr)) /
                      sum(ab))
              from batting
              where playerid = 'mayswi01')) as b
order by lslg desc, playerid
;

-- Question 4i
CREATE VIEW q4i(yearid, min, max, avg, stddev)
AS
SELECT yearid, min(salary), max(salary), avg(salary), stddev(salary)
from salaries
group by yearid
order by yearid;
;

-- Question 4ii
CREATE VIEW q4ii(binid, low, high, count)
AS
with ids as (select generate_series(0, 8) as binid),
     l as (select min(salary) as min from salaries where yearid = 2016),
     h as (select max(salary) as max from salaries where yearid = 2016)
select *
from (select ids.binid,
             ids.binid * (max - min) / 10 + min       as low,
             (ids.binid + 1) * (max - min) / 10 + min as high,
             (select count(*)
              from salaries
              where yearid = 2016
                and ids.binid * (max - min) / 10 + min <= salary
                and (ids.binid + 1) * (max - min) / 10 + min > salary)
      from ids,
           l,
           h
      union
      select 9,
             9 * (max - min) / 10 + min as low,
             max                        as high,
             (select count(*)
              from salaries
              where yearid = 2016
                and 9 * (max - min) / 10 + min <= salary
                and max >= salary)
      from ids,
           l,
           h) as s
order by binid
;

-- Question 4iii
CREATE VIEW q4iii(yearid, mindiff, maxdiff, avgdiff)
AS
with yearly as (select yearid, min(salary) as min, max(salary) as max, avg(salary) as avg from salaries group by yearid)
select y1.yearid, (y1.min - y2.min), (y1.max - y2.max), (y1.avg - y2.avg)
from yearly as y1,
     yearly as y2
where y1.yearid = y2.yearid + 1
order by y1.yearid;
;

-- Question 4iv
CREATE VIEW q4iv(playerid, namefirst, namelast, salary, yearid)
AS
select s.playerid, namefirst, namelast, salary, s.yearid
from (
         select playerid, salary, yearid
         from salaries
         where yearid = 2000
           and salary >= all (select salary from salaries where yearid = 2000)
         union
         select playerid, salary, yearid
         from salaries
         where yearid = 2001
           and salary >= all (select salary from salaries where yearid = 2001)
     ) as s
         natural join people
;
-- Question 4v
CREATE VIEW q4v(team, diffAvg) AS
select a.teamid, max(salary) - min(salary)
from allstarfull as a
         inner join salaries as s on a.playerid = s.playerid and a.yearid = s.yearid where a.yearid = 2016
group by a.teamid
;
