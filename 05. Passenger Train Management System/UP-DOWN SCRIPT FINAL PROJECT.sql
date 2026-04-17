if not exists(select * from sys.databases where name='FinalProject')
    create database FinalProject
GO

use FinalProject
GO

--Down
if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='d_maintenances_maintenance_date')
    alter table maintenances drop constraint d_maintenances_maintenance_date

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='d_orders_order_date')
    alter table orders drop constraint d_orders_order_date

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_tickets_order_id')
    alter table tickets drop constraint fk_tickets_order_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_tickets_trip_id')
    alter table tickets drop constraint fk_tickets_trip_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_trips_stations_station_id')
    alter table trips_stations drop constraint fk_trips_stations_station_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_trips_stations_trip_id')
    alter table trips_stations drop constraint fk_trips_stations_trip_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_trips_end_station_id')
    alter table trips drop constraint fk_trips_end_station_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_trips_start_station_id')
    alter table trips drop constraint fk_trips_start_station_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_trips_train_id')
    alter table trips drop constraint fk_trips_train_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_trips_conductor_id')
    alter table trips drop constraint fk_trips_conductor_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_customer_payment_methods_payment_method_id')
    alter table customer_payment_methods drop constraint fk_customer_payment_methods_payment_method_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_customer_payment_methods_customer_id')
    alter table customer_payment_methods drop constraint fk_customer_payment_methods_customer_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_maintenances_train_id')
    alter table maintenances drop constraint fk_maintenances_train_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_maintenances_technician_id')
    alter table maintenances drop constraint fk_maintenances_technician_id

if exists(select * from INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    where CONSTRAINT_NAME='fk_orders_customers_id')
    alter table orders drop constraint fk_orders_customers_id

drop table if exists tickets
drop table if exists trips_stations
drop table if exists trips
drop table if exists customer_payment_methods
drop table if exists maintenances
drop table if exists orders
drop table if exists technicians
drop table if exists stations
drop table if exists trains
drop table if exists conductors
drop table if exists passengers
drop table if exists payment_methods
drop table if exists customers


--Up Metadata
create table customers (
    customer_id int identity not null,
    customer_first_name varchar(50) not null,
    customer_last_name varchar(50) not null,
    customer_email varchar(100) not null,
    customer_phone_number varchar(10) not null,
    constraint pk_customers_customer_id primary key (customer_id),
    constraint u_customers_customer_email unique (customer_email),
    constraint u_customers_customer_phone_number unique (customer_phone_number),
    constraint ck_customers_customer_phone_digits check (customer_phone_number not like '%[^0-9]%')
)

create table payment_methods (
    payment_method_id int identity not NULL,
    payment_method_type varchar(20) not null,
    payment_method_number varchar(19) not NULL,
    payment_method_security_code varchar(4) not NULL,
    payment_method_expiry varchar(5) not null,
    constraint pk_payment_method_payment_method_id primary key (payment_method_id),
    constraint u_payment_method_payment_method_number unique (payment_method_number)
)

create table passengers (
    passenger_id int identity not NULL,
    passenger_first_name varchar(50) not null,
    passenger_last_name varchar(50) not null,
    passenger_email varchar(100) not null,
    passenger_phone_number varchar(10) not null,
    constraint pk_passengers_passenger_id primary key (passenger_id),
    constraint u_passengers_passenger_email unique (passenger_email),
    constraint u_passengers_passenger_phone_number unique (passenger_phone_number),
    constraint ck_passengers_passenger_phone_digits check (passenger_phone_number not like '%[^0-9]%')
)

create table conductors (
    conductor_id int identity not null,
    conductor_first_name varchar(50) not NULL,
    conductor_last_name varchar(50) not null,
    conductor_phone_number varchar(10) not null,
    constraint pk_conductors_conductor_id primary key (conductor_id),
    constraint u_conductors_conductor_phone_number unique (conductor_phone_number),
    constraint ck_conductors_conductor_phone_digits check (conductor_phone_number not like '%[^0-9]%')
)

create table trains (
    train_id int identity not null,
    train_name varchar(50) not null,
    train_type varchar(50) not null,
    train_capacity varchar(3) not null,
    constraint pk_trains_train_id primary key (train_id)
)

create table stations (
    station_id int identity not null,
    station_name varchar(100) not null,
    station_street_address varchar(100) not null,
    station_city varchar(50) not null,
    station_state varchar(2) not null,
    station_zip_code varchar(5) not null,
    constraint pk_stations_station_id primary key (station_id)
)

create table technicians (
    technician_id int identity not null,
    technician_first_name varchar(50) not null,
    technician_last_name varchar(50) not null,
    technician_phone_number varchar(10) not null,
    constraint pk_technicians_technician_id primary key (technician_id),
    constraint u_technicians_technician_phone_number unique (technician_phone_number),
    constraint ck_technicians_technician_phone_digits check (technician_phone_number not like '%[^0-9]%')
)

create table orders (
    order_id int identity not null,
    customer_id int not null,
    order_ticket_quantity int not null,
    order_date datetime not null,
    constraint pk_orders_order_id primary key (order_id),
    constraint ck_orders_order_ticket_quantity check (order_ticket_quantity > 0)
)

create table maintenances (
    maintenance_id int identity not null,
    technician_id int not NULL,
    train_id int not null,
    maintenance_date datetime not null,
    maintenance_description varchar(500) not null,
    constraint pk_maintenances_maintenance_id primary key (maintenance_id)
)

create table customer_payment_methods (
    customer_id int not null,
    payment_method_id int not null,
    constraint pk_customer_payment_methods primary key (customer_id, payment_method_id)
)

create table trips (
    trip_id int identity not null,
    conductor_id int not null,
    train_id int not null,
    start_station_id int not null,
    end_station_id int not null,
    trip_scheduled_departure_time datetime not null,
    trip_scheduled_arrival_time datetime not null,
    trip_distance_miles decimal(6,2) not null,
    trip_departure_status varchar(20) null,
    trip_arrival_status varchar(20) null,
    trip_actual_departure datetime null,
    trip_departure_platform int null,
    trip_arrival_platform int null,
    constraint pk_trips_trip_id primary key (trip_id),
    constraint ck_trips_estimated_arrival_departure_times check (trip_scheduled_arrival_time > trip_scheduled_departure_time),
    constraint ck_trips_actual_arrival_departure_times check (trip_actual_departure is null or trip_actual_departure >= trip_scheduled_departure_time),
    constraint ck_trips_trip_distance_miles check (trip_distance_miles > 0),
    constraint ck_trips_departure_status_options check (trip_departure_status is null or trip_departure_status in ('On Time', 'Delayed', 'Cancelled')),
    constraint ck_trips_arrival_status_options check (trip_arrival_status is null or trip_arrival_status in ('On Time', 'Delayed', 'Cancelled'))
)

create table trips_stations (
    trip_id int not null,
    station_id int not null,
    constraint pk_trips_stations primary key (trip_id, station_id)
)

create table tickets (
    ticket_id int identity not null,
    trip_id int not null,
    ticket_price money not null,
    ticket_status varchar(20) not null,
    order_id int null,
    passenger_id int null,
    ticket_seat_number varchar(4) null,
    constraint pk_tickets_ticket_id primary key (ticket_id),
    constraint ck_tickets_ticket_price check (ticket_price >= 0)
)

alter table orders
add constraint fk_orders_customers_id
    foreign key (customer_id)
    references customers(customer_id)

alter table maintenances
add constraint fk_maintenances_technician_id
    foreign key (technician_id)
    references technicians(technician_id)

alter table maintenances
add constraint fk_maintenances_train_id
    foreign key (train_id)
    references trains(train_id)

alter table customer_payment_methods
add constraint fk_customer_payment_methods_customer_id
    foreign key (customer_id)
    references customers(customer_id)

alter table customer_payment_methods
add constraint fk_customer_payment_methods_payment_method_id
    foreign key (payment_method_id)
    references payment_methods(payment_method_id)

alter table trips
add constraint fk_trips_conductor_id
    foreign key (conductor_id)
    references conductors(conductor_id)

alter table trips
add constraint fk_trips_train_id
    foreign key (train_id)
    references trains(train_id)

alter table trips
add constraint fk_trips_start_station_id
    foreign key (start_station_id)
    references stations(station_id)

alter table trips
add constraint fk_trips_end_station_id
    foreign key (end_station_id)
    references stations(station_id)

alter table trips_stations
add constraint fk_trips_stations_trip_id
    foreign key (trip_id)
    references trips(trip_id)

alter table trips_stations
add constraint fk_trips_stations_station_id
    foreign key (station_id)
    references stations(station_id)

alter table tickets
add constraint fk_tickets_trip_id
    foreign key (trip_id)
    references trips(trip_id)

alter table tickets
add constraint fk_tickets_order_id
    foreign key (order_id)
    references orders(order_id)

alter table tickets
add constraint fk_tickets_passenger_id
    foreign key (passenger_id)
    references passengers(passenger_id)

alter table orders
add constraint d_orders_order_date
    default getdate() for order_date

alter table maintenances
add constraint d_maintenances_maintenance_date
    default getdate() for maintenance_date

--Up Data
insert into customers
    (customer_first_name, customer_last_name, customer_email, customer_phone_number)
    VALUES
        ('Brealin', 'Redecker', 'blredeck@syr.edu', '6301648453'),
        ('Yida', 'Sun', 'ysun217@syr.edu', '1284026491'),
        ('Alexa', 'Lotano', 'alotano@syr.edu', '7102541826'),
        ('Joseph', 'Crimmer', 'jpcrimme@syr.edu', '1234567890')

insert into payment_methods
    (payment_method_type, payment_method_number, payment_method_security_code, payment_method_expiry)
    VALUES
        ('Visa', '4716483545913373', '775', '10/26'),
        ('Visa', '4539740521991730', '999', '02/27'),
        ('American Express', '340319741975703', '745', '06/28'),
        ('MasterCard', '5527507665084619', '110', '05/28'),
        ('Visa', '4262736473829406', '283', '08/26')

insert into passengers
    (passenger_first_name, passenger_last_name, passenger_email, passenger_phone_number)
    VALUES
        ('Brealin', 'Redecker', 'blredeck@syr.edu', '6301648453'),
        ('Yida', 'Sun', 'ysun217@syr.edu', '1284026491'),
        ('Alexa', 'Lotano', 'alotano@syr.edu', '7102541826'),
        ('Joseph', 'Crimmer', 'jpcrimme@syr.edu', '1234567890'),
        ('Francis', 'Ewing','francisrules@gmail.com', '3364363961'),
        ('Chris', 'McCann', 'mccannchris@outlook.com', '4087929690'),
        ('Judith', 'Velazquez', 'JudithTVelazquez@armyspy.com', '8317636873')

insert into conductors
    (conductor_first_name, conductor_last_name, conductor_phone_number)
    VALUES
        ('David', 'Vogel', '2405231871'),
        ('Bruce', 'Frost', '3303865550'),
        ('Nelson', 'Wong', '3102122210')

insert into trains
    (train_name, train_type, train_capacity)
    VALUES
        ('Zephyr', 'Passenger', '250'),
        ('Bullet', 'High-Speed Rail', '500'),
        ('Chief', 'Passenger', '300'),
        ('Thomas', 'Overnight Passenger', '300'),
        ('Percy', 'Overnight Passenger','250')

insert into stations
    (station_name, station_street_address, station_city, station_state, station_zip_code)
VALUES
    ('Syracuse Walsh Regional Transportation Centre', '1 Walsh Cir', 'Syracuse', 'NY', '13208'),
    ('Louise M. Slaughter Rochester Station', '320 Central Ave', 'Rochester', 'NY', '14605'),
    ('Albany-Rensselaer Station', '525 East Street', 'Rensselaer', 'NY', '12144'),
    ('Buffalo Central Terminal', '495 Paderewski Drive', 'Buffalo', 'NY', '14212'),
    ('South Station', '700 Atlantic Ave', 'Boston', 'MA', '02110'),
    ('Grand Central Station', '49 East 42nd Street', 'New York City', 'NY', '10017'),
    ('Newark Penn Station', '1 Raymond Plaza West & Market Street', 'Newark', 'NJ', '07102'),
    ('Hartford Union Station', '1 Union Place', 'Hartford', 'CT', '06103'),
    ('Concord Transportation Centre', '30 Stickney Ave', 'Concord', 'NH', '03301')

insert into technicians
    (technician_first_name, technician_last_name, technician_phone_number)
    VALUES
        ('Stephen', 'Wood', '5024396593'),
        ('Sharon', 'Kirkman', '2813989729'),
        ('Lona', 'Luczak', '9722480197')

insert into orders
    (customer_id, order_ticket_quantity)
    VALUES
        (2, 3), 
        (1, 5),
        (4, 2), 
        (3, 1),
        (3, 2), 
        (2, 1),
        (1, 9),
        (1, 1),
        (4, 1),
        (2, 2)

insert into maintenances
    (technician_id, train_id, maintenance_description)
    VALUES
        (3, 1, 'Monthly inspection. Passed.'),
        (3, 2, 'Monthly inspection. Passed.'),
        (3, 3, 'Monthly inspection. Failed. Needs replacement grind rails.'),
        (2, 4, 'Monthly inspection. Passed.'),
        (1, 5, 'Monthly inspection. Failed. Needs replacement engine.'),
        (1, 5, 'Replaced engine, train should function as intended now.')

insert into customer_payment_methods
    (customer_id, payment_method_id)
    values
        (2, 1),
        (1, 2),
        (4, 3),
        (3, 4),
        (1, 5)

insert into trips
    (conductor_id, train_id, start_station_id, end_station_id, trip_scheduled_departure_time, trip_scheduled_arrival_time, trip_distance_miles)
    VALUES
        (3, 2, 4, 3, '2025-12-07 14:30:00', '2025-12-07 18:00:00', 291.32), --Buffalo to Albany
        (1, 4, 2, 9, '2025-12-11 17:00:00', '2025-12-12 02:45:00', 369.05), --Rochester to Concord
        (2, 1, 1, 5, '2025-12-12 10:45:00', '2025-12-12 20:00:00', 313.17) --Syracuse to Boston

insert into tickets
    (trip_id, ticket_price, ticket_status, order_id, passenger_id)
    VALUES
        (1, 60.00, 'Completed', 3, 4),
        (1, 60.00, 'Completed', 3, 6),
        (3, 180.00, 'Booked', 7, 1),
        (3, 180.00, 'Cancelled', 7, 2),
        (3, 180.00, 'Cancelled', 7, 6),
        (3, 180.00, 'Booked', 7, 5),
        (2, 110.00, 'Booked', 10, 2),
        (2, 110.00, 'Booked', 10, 3)

insert into trips_stations 
    (trip_id, station_id)
    VALUES
        (1, 4),
        (1, 2),
        (1, 1),
        (1, 3),
        (2, 2),
        (2, 1),
        (2, 3),
        (2, 5),
        (2, 9),
        (3, 1),
        (3, 3),
        (3, 8),
        (3, 5)


--Verify
select * from customers
select * from payment_methods
select * from passengers
select * from conductors
select * from trains
select * from stations
select * from technicians
select * from orders
select * from maintenances
select * from customer_payment_methods
select * from trips
select * from trips_stations
select * from tickets

