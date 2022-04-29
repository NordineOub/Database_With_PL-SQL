# Creation of a Database with PL/SQL Procedures and functions

This project is an example of using events and triggers in PL/SQL. 
This project creates a network of theater companies, their ticket and show management. The situation is explained with this E/A Class diagram :

<img width="1091" alt="image" src="https://user-images.githubusercontent.com/75072085/165896180-81dd1d0a-e24f-48c3-afa0-c44f866e3ad8.png">

There is also this relational model between each table : 

<img width="1147" alt="image" src="https://user-images.githubusercontent.com/75072085/165898656-2d5948b0-be56-48c1-b6cc-e465681b8b5a.png">


## How to install it

We created and managed this project with Oracle SQL, so our script may be not functional on other SQL database.
You can try Oracle SQL online and for free here : https://livesql.oracle.com/

Then we copy and run each sql file from part 1 to part 3.
Finally you can write and check the results of the procedures and functions which we will detail below 

## Conditions & Management
### Ticket Discount
When a customer buys a ticket for a specific show at a specific date and depending on its age, they will benefit a discount (insertion a new line):

- 20% if the ticket is bought 15 days before the show
- 30% discount if it is the day of show and it less than 50% of tickets are sold
- 50% if less than 30% of the tickets are sold

### Grant Management
Before inserting into grants amount of donations and period, the script should check the agency's nature on insertion. 
This allows to verify if these grants are from public or private funds.

## Functionalities

### Coincidence show

Question : Would a company be provided for two theaters at the same time? Are both shows presented in the same place?

Answer : The stored procedure "pr_resultat( room name, date)"

         - With a cursor (select) that counts the number of shows at a specified date and in a specified theater room.
         
         - That will check whether theater shows overlap or not.

### Cities of show per period

Question : What is the set of cities in which a company plays for a certain period?  

Answer : The stored procedure "cityshow( starting date, closing date)".

### Distribution per representation

Question : For each representation, what is the distribution of tickets by price, tariff...? 

Answer : The stored procedure "Distribution()".

### Average Load Factor

Question :For each theater, what is the average load factor ?

Answer : he stored procedure "loadFactor(Show ID)".

### Balance promptly in red

Question : The first date when the balance of a theater will move promptly to the red (in the hypothesis when no ticket is sold out).

Answer :

Part 1 - Function to count the number of tickets left => Function "TICKETS(Company ID)"

Part 2 - Function to calculate the balance of a company => Function"BALANCE(Company ID)"

Part 3 - Table for the history accounting of the companies => Temporary table "accountingHistory"

Part 4 - Trigger to retrieve the balance and the date of occurence => Trigger "TICKETS_LEFT"

### Balance permanently in red

Question : The first date when the balance of a theater will move permanently to the red (in the hypothesis when no ticket is sold out, and the expected revenue does not offset enough).

Answer : Stored procedure "pr_red_balance()"

### Number Ticket for balance

Question : Are there enough tickets for sale to avoid these situations? Hypothesis where all tickets are sold (which is different from revenues).

Answer : Stored procedure "CHECK_BALANCE()"

### Effective Cost

Question : A show given by a company was sold out with a certain price. Is it cost effective for the company? (Compared to costs incurred (salaries, travel, staging)

Answer : Stored procedure "COST_EFFECTIVE()"

### First date Show

Question : Are there companies that will never play in their theater? Select which ones systematically make their first show at home? And outside?

Answer : Function "FIRST_DATE_SHOW(Production ID)"

### Popular shows per period

Question :What are the most popular shows in a certain period? 

Answer : Stored procedure "popular_show(starting date , closing date)"

### Number of representations

Question : What is the number of representations per show ?

Answer : Stored procedure "Number_rep(Show ID)"

### Number of potential viewers

Question : What is the number of potential viewers ?

Answer : Stored procedure "Potential_viewer(Show ID)" 

### Number of seats sold
Question : What is the number of seats sold ?

Answer : Stored procedure "Seat_Sold(Production ID)" 
