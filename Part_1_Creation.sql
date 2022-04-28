CREATE TABLE Theater_Company(
   company_id INT,
   company_name VARCHAR(50),
   revenues INT,
   expenditures INT,
   PRIMARY KEY(company_id)
);

CREATE TABLE Theater_room(
   hall_id INT,
   room_name VARCHAR(50),
   capacite INT,
   localisation VARCHAR(50),
   company_id INT NOT NULL,
   PRIMARY KEY(hall_id),
   UNIQUE(company_id),
   FOREIGN KEY(company_id) REFERENCES Theater_Company(company_id)
);

CREATE TABLE Show(
   show_id INT,
   production_costs DECIMAL(15,2),
   nb_actors INT,
   capacity_tickets_available INT,
   PRIMARY KEY(show_id)
);

CREATE TABLE Production(
   production_id INT,
   prod_description VARCHAR(50),
   company_id INT NOT NULL,
   PRIMARY KEY(production_id),
   FOREIGN KEY(company_id) REFERENCES Theater_Company(company_id)
);

CREATE TABLE Ticket(
   pricing_id INT,
   price DECIMAL(15,2),
   PRIMARY KEY(pricing_id)
);

CREATE TABLE Discount(
   discount_id INT,
   discount_rate DECIMAL(15,2),
   PRIMARY KEY(discount_id)
);

CREATE TABLE Agency(
   agency_id INT,
   agency_name VARCHAR(50),
   nature VARCHAR(50),
   PRIMARY KEY(agency_id)
);

CREATE TABLE Customer(
   customer_id INT,
   customer_name VARCHAR(50),
   social_state VARCHAR(50),
   PRIMARY KEY(customer_id)
);

CREATE TABLE sells(
   show_id INT,
   pricing_id INT,
   PRIMARY KEY(show_id, pricing_id),
   FOREIGN KEY(show_id) REFERENCES Show(show_id),
   FOREIGN KEY(pricing_id) REFERENCES Ticket(pricing_id)
);

CREATE TABLE performs(
   hall_id INT,
   show_id INT,
   production_id INT,
   date_show DATE,
   PRIMARY KEY(hall_id, show_id, production_id),
   FOREIGN KEY(hall_id) REFERENCES Theater_room(hall_id),
   FOREIGN KEY(show_id) REFERENCES Show(show_id),
   FOREIGN KEY(production_id) REFERENCES Production(production_id)
);

CREATE TABLE grants(
   company_id INT,
   agency_id INT,
   subsidies DECIMAL(15,2),
   begin_date DATE,
   end_date DATE,
   PRIMARY KEY(company_id, agency_id),
   FOREIGN KEY(company_id) REFERENCES Theater_Company(company_id),
   FOREIGN KEY(agency_id) REFERENCES Agency(agency_id)
);

CREATE TABLE proposes(
   pricing_id INT,
   discount_id INT,
   PRIMARY KEY(pricing_id, discount_id),
   FOREIGN KEY(pricing_id) REFERENCES Ticket(pricing_id),
   FOREIGN KEY(discount_id) REFERENCES Discount(discount_id)
);

CREATE TABLE paies(
   pricing_id INT,
   customer_id INT,
   payment_date DATE,
   PRIMARY KEY(pricing_id, customer_id),
   FOREIGN KEY(pricing_id) REFERENCES Ticket(pricing_id),
   FOREIGN KEY(customer_id) REFERENCES Customer(customer_id)
);
