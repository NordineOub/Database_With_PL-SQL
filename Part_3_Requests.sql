CREATE OR REPLACE FUNCTION GET_DISCOUNT_ID(RATE NUMBER) RETURN NUMBER IS
DISC_ID NUMBER;
BEGIN
SELECT DISCOUNT_ID INTO DISC_ID FROM DISCOUNT WHERE DISCOUNT_RATE=RATE ;
RETURN DISC_ID;
END;
/

create or replace trigger ticketingDiscount BEFORE INSERT ON paies
FOR EACH ROW
DECLARE
CURSOR CUSTOMERS IS
select c.social_state, c.customer_id, p.pricing_id, p.payment_date, per.date_show, sh.capacity_tickets_available as capac, th_r.capacite from customer c
join paies p on c.customer_id = p.customer_id join ticket t on p.pricing_id=t.pricing_id
join sells s on s.pricing_id=t.pricing_id
join show sh on sh.show_id=s.show_id
join performs per on per.show_id=sh.show_id join theater_room th_r on th_r.hall_id=per.hall_id; id_show NUMBER;
discount_id_ NUMBER;
BEGIN
SELECT show_id INTO id_show from show join sells using(show_id) join ticket using(pricing_id) join
paies using(pricing_id) where customer_id = :new.customer_id; FOR ct in CUSTOMERS LOOP
-- decrement available tickets
UPDATE Show SET capacity_tickets_available = capacity_tickets_available - 1 WHERE show_id = id_show ;
-- check if normal_reference_rate or reduced_reference_rate on ticket table (children, students, elderly, unemployed
IF ct.social_state = 'Child' OR ct.social_state = 'Elderly' OR ct.social_state = 'Student' OR ct.social_state = 'Unemployed' THEN
-- reduced_reference_rate ??? -20% ???
UPDATE TICKET SET price = price * 0.8 WHERE pricing_id = ct.pricing_id; --DBMS_OUTPUT.PUT_LINE('The customer benefits a discount because he is less than 18 years old'); --INSERT INTO PROPOSES(PRICING_ID, DISCOUNT_ID) VALUES();
END IF;
IF ct.date_show - ct.payment_date >= 15 THEN
-- retrieve discount_id where rate = 0.8 (-20%)
SELECT GET_DISCOUNT_ID(0.8) INTO DISCOUNT_ID_ FROM DUAL;
ELSIF ct.date_show = ct.payment_date THEN -- and less than 50% of tickets sold
-- retrieve discount_id where rate = 0.7 (-30%)
SELECT GET_DISCOUNT_ID(0.7) INTO DISCOUNT_ID_ FROM DUAL;
ELSIF ct.capac/ct.capacite <= 0.7 THEN -- if less than 30% tickets sold
-- retrieve discount_id where rate = 0.5 (-50%)
SELECT DISCOUNT_ID INTO DISCOUNT_ID_ FROM DISCOUNT WHERE DISCOUNT_RATE = 0.7; -- update ticket price
END IF;
INSERT INTO PROPOSES(PRICING_ID,DISCOUNT_ID) VALUES(CT.PRICING_ID,DISCOUNT_ID_); EXIT when CUSTOMERS%NOTFOUND;
END LOOP;
END; /

CREATE OR REPLACE TRIGGER grant_management
BEFORE INSERT ON grants -- we fill only company_id, agency_id, if subsidies, begin and end_date already filled, we gotta update them
FOR EACH ROW
DECLARE
CURSOR info IS
SELECT nature, company_id, agency_id from agency join grants using(agency_id)
join theater_company using(company_id)
where agency_id = :new.agency_id;
nature_ag VARCHAR; comp NUMBER;
ag NUMBER;
BEGIN
-- subsidies from a specific agency OPEN info;
FETCH info.nature into nature_ag; FETCH info.company_id into comp; FETCH info.agency_id into ag;
IF nature_ag = 'private_donors' then
update grants SET subsidies = 500, begin_date = SYSDATE, end_date = SYSDATE + 5 where company_id = comp and agency_id = ag;
END IF;
IF nature_ag = 'Municipality' then
update grants SET subsidies = 500, begin_date = SYSDATE, end_date = SYSDATE + 5 where company_id = comp and agency_id = ag;
END IF;
IF nature_ag = 'NGO' then
update grants SET subsidies = 500, begin_date = SYSDATE, end_date = SYSDATE + 5 where company_id = comp and agency_id = ag;
END IF;
END; /

CREATE OR REPLACE PROCEDURE pr_resultat (salle_name Varchar,sw_date DATE) IS BEGIN
DECLARE
CURSOR SHOWS IS
select count(show_id) as nb_rep, hall_id, date_show, room_name AS SHOW_SPEC from performs inner join theater_room using(hall_id) inner join show using(show_id)
where room_name = salle_name and date_show = sw_date group by hall_id, date_show, room_name ;
BEGIN
FOR SH IN SHOWS LOOP
DBMS_OUTPUT.PUT_LINE('From the following hall id : ' || SH.hall_id || ', and the following date show : ' || SH. date_show || ' , We have this number of representations : : ' || SH.nb_rep );
EXIT when shows%NOTFOUND;
END LOOP; END;
END; /

CREATE OR REPLACE PROCEDURE cityshow(begin_date DATE, end_date DATE) IS BEGIN
DECLARE
CURSOR CITIES IS
select distinct company_id, room_name, capacite, hall_id, performs.date_show, localisation from theater_room
inner join theater_company using(company_id)
inner join performs using(hall_id)
where performs.date_show between begin_date and end_date;
BEGIN
FOR CT IN CITIES LOOP
DBMS_OUTPUT.PUT_LINE('The company n° ' || CT.company_id || ' in room ' || CT.room_name || ' of capacity of ' || CT.CAPACITE || ' people ' || CT.HALL_ID || ' (HALL_ID) performs the ' || CT.DATE_SHOW || ' at ' || CT.LOCALISATION);
EXIT when cities%NOTFOUND;
END LOOP; END;
END; /

CREATE OR REPLACE PROCEDURE Distribution IS BEGIN
DECLARE
CURSOR factors IS
select show_id, count(price) as distribution, price from ticket inner join sells using(pricing_id) inner join show using(show_id) group by show_id, price order by price asc;
BEGIN
FOR CT IN factors LOOP
DBMS_OUTPUT.PUT_LINE('For the following show ID : ' || CT.show_id || ' we have this number of ticket ' ||CT.distribution ||'and this price : '|| CT.price || '$');
EXIT when factors%NOTFOUND;
END LOOP; END;
END; /

CREATE OR REPLACE PROCEDURE loadFactor( id_show Number) IS BEGIN
DECLARE
CURSOR factors IS
select avg(CAPACITY_TICKETS_AVAILABLE/capacite) as factor, show_id
from theater_room inner join performs using(hall_id) inner join show using(show_id) where show_id = id_show group by show_id ;
BEGIN
FOR CT IN factors LOOP
DBMS_OUTPUT.PUT_LINE('The average load factor is '||Round(CT.factor,2) || ' in the show with this id value : ' || CT.show_id);
EXIT when factors%NOTFOUND;
END LOOP; END;
END; /

CREATE OR REPLACE FUNCTION TICKETS(CompID THEATER_COMPANY.COMPANY_ID%TYPE)
RETURN NUMBER IS
TICKETS_LEFT NUMBER ;
BEGIN
SELECT CAPACITY_TICKETS_AVAILABLE INTO TICKETS_LEFT FROM THEATER_COMPANY
INNER JOIN THEATER_ROOM USING(COMPANY_ID) INNER JOIN PERFORMS USING(HALL_ID) INNER JOIN SHOW USING(SHOW_ID)
WHERE COMPANY_ID=CompID ;
RETURN TICKETS_LEFT;
END; /

CREATE OR REPLACE FUNCTION BALANCE(CompID THEATER_COMPANY.COMPANY_ID%TYPE)
RETURN NUMBER IS
NEW_BALANCE NUMBER ;
BEGIN
SELECT revenues - expenditures INTO NEW_BALANCE FROM THEATER_COMPANY
WHERE COMPANY_ID=CompID ; RETURN NEW_BALANCE;
END;
/


CREATE TABLE accountingHistory (
balance_state VARCHAR2(50), -- add constraint either in green or balance in red
Date_accounting DATE,
Amount NUMBER );

CREATE OR REPLACE TRIGGER TICKETS_lEFT
AFTER UPDATE OF REVENUES, EXPENDITURES ON THEATER_COMPANY FOR EACH ROW
DECLARE
NB_TICKETS_AVAILABLE NUMBER;
NEW_BALANCE NUMBER;
BEGIN
-- verify no ticket are sold out
SELECT TICKETS(:NEW.COMPANY_ID) INTO NB_TICKETS_AVAILABLE FROM DUAL;
IF NB_TICKETS_AVAILABLE > 0 THEN
-- retrieve the balance of the concerned theater_company
SELECT BALANCE(:NEW.COMPANY_ID) INTO NEW_BALANCE FROM DUAL; -- retrieve the first date when occurred => SYSDATE (???)
INSERT INTO accountingHistory(balance_state,Date_accounting,Amount) VALUES('red', SYSDATE, NEW_BALANCE);
END IF;
END;
/


CREATE OR REPLACE PROCEDURE pr_red_balance IS BEGIN
DECLARE
CURSOR red_balance IS
SELECT Theater_company.company_id, (Theater_company.revenues -
Theater_company.expenditures) balance, performs.date_show from Theater_company left join theater_room on Theater_company.company_id = theater_room.company_id left join performs on theater_room.hall_id = performs.hall_id
where (Theater_company.revenues - Theater_company.expenditures) <0 order by performs.date_show DESC;
BEGIN
FOR CT IN red_balance LOOP
DBMS_OUTPUT.PUT_LINE('The company with the id ' || CT.company_id||' have a permanent red balance of '||CT.balance || '$ in the following date ' || CT.date_show);
EXIT when red_balance%NOTFOUND;
END LOOP; END;
END; /

CREATE OR REPLACE PROCEDURE CHECK_BALANCE IS BEGIN
DECLARE
CURSOR BALANCES IS
SELECT (show.capacity_tickets_available * Ticket.price - show.production_costs)
balance, performs.date_show, company_id from Ticket join sells using(pricing_id)
join show using(show_id)
join performs using(show_id)
join theater_room using(hall_id)
join theater_company using(company_id) ; BEGIN
FOR bal IN BALANCES LOOP IF BAL.BALANCE > 0 THEN
DBMS_OUTPUT.PUT_LINE('Company number' || BAL.COMPANY_ID || ' => prediction balance after selling all tickets :'|| BAL.BALANCE ||': the theater company can counterbalance if it succeeds to sell all its tickets');
ELSE
DBMS_OUTPUT.PUT_LINE('Company_number' || BAL.COMPANY_ID || '=>
prediction balance after selling all tickets :' || BAL.BALANCE ||': the theater company couldnt counterbalance even if it succeeds to seel all its tickets');
END IF;
EXIT when balances%NOTFOUND; END LOOP;
END; END;
/


CREATE OR REPLACE PROCEDURE COST_EFFECTIVE IS BEGIN
DECLARE
CURSOR BALANCES IS
select (revenues - expenditures) as balance, price, production_costs, company_id from
theater_company
join theater_room using(company_id) join performs using(hall_id)
join show using(show_id)
join sells using(show_id)
join ticket using(pricing_id)
where company_id = 1;
BEGIN
FOR bal IN BALANCES LOOP
IF BAL.BALANCE > BAL.production_costs THEN DBMS_OUTPUT.PUT_LINE('Company number ' || BAL.COMPANY_ID || ' => balance
counterbalances the production costs : ' || BAL.BALANCE || '€ > ' || BAL.PRODUCTION_COSTS ||'' || BAL.PRICE || '€');
ELSE
DBMS_OUTPUT.PUT_LINE('Company number ' || BAL.COMPANY_ID || ' => balance
doesnt counterbalance the production costs : ' || BAL.BALANCE || '€ < ' || BAL.PRODUCTION_COSTS || '' || BAL.PRICE || '€');
END IF;
EXIT when balances%NOTFOUND; END LOOP;
END; END;
/

REATE OR REPLACE FUNCTION FIRST_DATE_SHOW(PROD_ID NUMBER)
RETURN DATE IS
DATE_SHOW_FST PERFORMS.DATE_SHOW%TYPE;
BEGIN
SELECT MIN(DATE_SHOW) INTO DATE_SHOW_FST FROM PERFORMS WHERE
PRODUCTION_ID = PROD_ID; RETURN DATE_SHOW_FST;
END; /
CREATE OR REPLACE PROCEDURE OCCURRENCE_PLACE IS BEGIN
DECLARE
CURSOR COMPANIES IS
SELECT distinct theater_company.company_id as th_id, performs.date_show, production.prod_description, production.company_id as prod_id FROM performs
left join theater_room on performs.hall_id = theater_room.hall_id
left join theater_company on theater_company.company_id =theater_room.company_id
join production using(production_id)
order by performs.date_show ASC; first_date DATE;
BEGIN
FOR CPN IN COMPANIES LOOP
SELECT FIRST_DATE_SHOW(cpn.prod_id) INTO first_date FROM DUAL; IF cpn.prod_id != cpn.th_id THEN
DBMS_OUTPUT.PUT_LINE('Company number ' || cpn.th_id || ' never plays in its room but plays in room number ' || cpn.prod_id);
IF first_date = cpn.date_show THEN
DBMS_OUTPUT.PUT_LINE('Company number ' || cpn.th_id || ' plays outside its
room number ' || cpn.prod_id || ' for its first date of show ' || cpn.date_show); END IF;
ELSE
-- retrieve all the dates of show from a specific company playing at its own theater room
-- select the earliest one into first_date_show IF first_date = cpn.date_show THEN
DBMS_OUTPUT.PUT_LINE('Company number ' || cpn.th_id || ' plays in its room number ' || cpn.prod_id || ' for its first date of show ' || cpn.date_show);
ELSE
DBMS_OUTPUT.PUT_LINE('Company number ' || cpn.th_id || ' plays in its room
number ' || cpn.prod_id); END IF;
END IF;
EXIT when companies%NOTFOUND; END LOOP;
END; END;
/

CREATE OR REPLACE PROCEDURE popular_show(begin_date DATE, end_date DATE) IS BEGIN
DECLARE
CURSOR SHOW IS
SELECT show_id, count(show_id) as compte FROM performs WHERE date_show between begin_date and end_date group by show_id
order by compte DESC
fetch first 1 rows only; BEGIN
FOR CH IN SHOW LOOP
DBMS_OUTPUT.PUT_LINE('The show number ' || CH.show_id || ' is the most popular :
it is performed ' || CH.compte || ' times.'); EXIT when SHOW%NOTFOUND; END LOOP;
END;
END; /

CREATE OR REPLACE PROCEDURE Number_rep(id_show NUMBER) IS BEGIN
DECLARE
CURSOR SHOW IS
SELECT production.production_id, count(performs.date_show) as nombre_representation FROM production
left join performs on production.production_id = performs.production_id where performs.show_id = id_show
group by production.production_id;
BEGIN
FOR SH IN SHOW LOOP
DBMS_OUTPUT.PUT_LINE('The production with the ID '||SH.production_id || ' is played ' || SH.nombre_representation || ' times.');
EXIT when SHOW%NOTFOUND;
END LOOP; END;
END; /


CREATE OR REPLACE PROCEDURE Potential_viewer(id_show NUMBER) IS BEGIN
DECLARE
CURSOR SHOW IS
SELECT production.production_id, Theater_room.capacite FROM production left join performs on production.production_id = performs.production_id
left join Theater_room on Theater_room.hall_id = performs.hall_id
where performs.show_id = id_show;
BEGIN
FOR SH IN SHOW LOOP
DBMS_OUTPUT.PUT_LINE('The production with the ID '||SH.production_id || ' has ' || SH.capacite || ' potential viewers.');
EXIT when SHOW%NOTFOUND;
END LOOP; END;
END; /


CREATE OR REPLACE PROCEDURE Seat_Sold(id_prod NUMBER) IS BEGIN
DECLARE
CURSOR PROD IS
SELECT production.production_id, show.capacity_tickets_available FROM production
left join performs on production.production_id = performs.production_id left join show on performs.show_id = show.show_id
where performs.production_id = id_prod;
BEGIN
FOR PR IN PROD LOOP
DBMS_OUTPUT.PUT_LINE('The production with the ID '||PR.production_id || ' has ' || PR.capacity_tickets_available || ' seats sold.');
EXIT when prod%NOTFOUND;
END LOOP; END;
END; /

