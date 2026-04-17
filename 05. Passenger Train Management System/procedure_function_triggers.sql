USE FinalProject;
GO


DROP PROCEDURE IF EXISTS p_update_trip_status;
GO

-- Stored Procedure 1: Update Trip Status and Actual Times (p_update_trip_status)
-- Business Scenario: When a train departs or arrives, dispatchers or conductors need to update
-- the trip status (e.g., 'On Time', 'Delayed') and the actual departure or arrival time.
CREATE PROCEDURE p_update_trip_status
    @trip_id INT,
    @update_type VARCHAR(10), -- Pass in 'DEPARTURE' or 'ARRIVAL'
    @status VARCHAR(20),      -- Pass in 'On Time', 'Delayed', 'Cancelled'
    @actual_time DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- Data Validation: Ensure the trip exists.
    IF NOT EXISTS (SELECT 1 FROM trips WHERE trip_id = @trip_id)
    BEGIN
        PRINT 'Error: Trip ID not found.';
        RETURN;
    END

    -- Update different fields based on the update type.
    IF @update_type = 'DEPARTURE'
    BEGIN
        UPDATE trips
        SET trip_departure_status = @status,
            trip_actual_departure = @actual_time
        WHERE trip_id = @trip_id;
        PRINT 'Trip departure status updated successfully.';
    END
    ELSE IF @update_type = 'ARRIVAL'
    BEGIN
        -- Validate that arrival time cannot be earlier than departure time (if already departed).
        DECLARE @dept_time DATETIME;
        SELECT @dept_time = trip_actual_departure FROM trips WHERE trip_id = @trip_id;

        IF @dept_time IS NOT NULL AND @actual_time < @dept_time
        BEGIN
             PRINT 'Error: Actual arrival time cannot be before actual departure time.';
             RETURN;
        END

        -- Update arrival status. 
        UPDATE trips
        SET trip_arrival_status = @status
        WHERE trip_id = @trip_id;
        
        PRINT 'Trip arrival status updated successfully (Note: Actual arrival time was not stored as the column does not exist in the current trips table schema).';
    END
    ELSE
    BEGIN
        PRINT 'Error: Invalid update type. Use DEPARTURE or ARRIVAL.';
    END
END;
GO

--PROCEDURE EXECUTION 1: p_update_trip_status
USE FinalProject;
GO

-- 1. View current status (trip_id 1 departure_status and actual_departure should be NULL).
SELECT trip_id, trip_scheduled_departure_time, trip_departure_status, trip_actual_departure 
FROM trips WHERE trip_id = 1;

-- 2. Execute stored procedure, set delayed status and depart.
-- This should execute successfully and show "Trip departure status updated successfully."
EXEC p_update_trip_status 
    @trip_id = 1, 
    @update_type = 'DEPARTURE', 
    @status = 'Delayed', 
    @actual_time = '2025-12-07 14:55:00'; -- 25 minutes later than scheduled

-- 3. View status again to verify changes.
SELECT trip_id, trip_scheduled_departure_time, trip_departure_status, trip_actual_departure 
FROM trips WHERE trip_id = 1;



-- PROCEDURE 2: Quick Ticket Purchase

-- Quick Ticket Purchase (p_quick_purchase_ticket)
-- Business Scenario: This is a simplified ticketing process used to quickly insert a ticket record
-- given an existing order, passenger, and trip. This demonstrates the use of transactions.
USE FinalProject;
GO

CREATE PROCEDURE p_quick_purchase_ticket
    @trip_id INT,
    @order_id INT,
    @passenger_id INT,
    @price MONEY,
    @seat_number VARCHAR(4)
AS
BEGIN
    SET NOCOUNT ON;

    -- Begin transaction to ensure atomicity of the ticket purchase operation.
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Simple validation (real projects need more complex validation, such as checking if full, if order exists, etc.).
        IF NOT EXISTS (SELECT 1 FROM trips WHERE trip_id = @trip_id) THROW 50001, 'Trip not found.', 1;
        IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = @order_id) THROW 50002, 'Order not found.', 1;

        -- 2. Insert ticket.
        INSERT INTO tickets (trip_id, ticket_price, ticket_status, order_id, passenger_id, ticket_seat_number)
        VALUES (@trip_id, @price, 'Booked', @order_id, @passenger_id, @seat_number);

        -- 3. Commit transaction.
        COMMIT TRANSACTION;
        PRINT 'Ticket purchased successfully.';
    END TRY
    BEGIN CATCH
        -- If an error occurs, rollback transaction.
        ROLLBACK TRANSACTION;
        PRINT 'Error purchasing ticket: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- TESTING PROCEDURE 2:  p_quick_purchase_ticket

-- 1. View ticket count before execution (trip_id=2 currently has 2 tickets).
SELECT COUNT(*) AS TicketCount_Trip2 FROM tickets WHERE trip_id = 2;

-- 2. Execute  stored procedure to purchase ticket
EXEC p_quick_purchase_ticket
    @trip_id = 2,
    @order_id = 10,
    @passenger_id = 4,
    @price = 120.00,
    @seat_number = 'A15';

-- 3. Verify if the new ticket was inserted.
SELECT * FROM tickets WHERE trip_id = 2 AND passenger_id = 4 AND ticket_seat_number = 'A15';
-- verify
SELECT COUNT(*) AS TicketCount_Trip2_After FROM tickets WHERE trip_id = 2;




-- Function: Calculate Scheduled Trip Duration
USE FinalProject;
GO

CREATE FUNCTION f_get_scheduled_duration_minutes (@trip_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @duration INT;

    SELECT @duration = DATEDIFF(MINUTE, trip_scheduled_departure_time, trip_scheduled_arrival_time)
    FROM trips
    WHERE trip_id = @trip_id;

    -- If trip not found, return NULL.
    RETURN @duration;
END;
GO

-- TESTING FUNCTION 1: f_get_scheduled_duration_minutes
-- Call scalar function using SELECT.
SELECT 
    trip_id, 
    trip_scheduled_departure_time, 
    trip_scheduled_arrival_time,
    dbo.f_get_scheduled_duration_minutes(trip_id) AS ScheduledDurationMinutes
FROM trips
WHERE trip_id = 1;

--- Function: Get all station names visited on a specific trip.
USE FinalProject;
GO

CREATE FUNCTION f_get_trip_station_names (@trip_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        ts.trip_id,
        s.station_name,
        s.station_city,
        s.station_state
    FROM trips_stations ts
    INNER JOIN stations s ON ts.station_id = s.station_id
    WHERE ts.trip_id = @trip_id
);
GO
-- Call table-valued function just like querying a table.
SELECT * FROM dbo.f_get_trip_station_names(3);




--- Trigger: Automatically cancel associated tickets when a trip is cancelled.

USE FinalProject;
GO

CREATE TRIGGER t_cancel_tickets_on_trip_cancellation
ON trips
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if trip_departure_status field was updated and the new status is 'Cancelled'.
    -- Use 'inserted' temporary table to get the new updated values.
    IF UPDATE(trip_departure_status) AND EXISTS (SELECT 1 FROM inserted WHERE trip_departure_status = 'Cancelled')
    BEGIN
        UPDATE t
        SET t.ticket_status = 'Cancelled'
        FROM tickets t
        INNER JOIN inserted i ON t.trip_id = i.trip_id
        WHERE t.ticket_status = 'Booked'; -- Only cancel tickets that are currently in 'Booked' status.

        PRINT 'Trigger fired: Associated tickets have been cancelled due to trip cancellation.';
    END
END;
GO

-- TESTING TRIGGER 1: t_cancel_tickets_on_trip_cancellation

-- 1. View current ticket statuses for trip_id 2 (should have 'Booked' status tickets).
SELECT ticket_id, trip_id, ticket_status FROM tickets WHERE trip_id = 2;

-- 2. Manually update trips table to fire the trigger.
UPDATE trips 
SET trip_departure_status = 'Cancelled' 
WHERE trip_id = 2;

-- 3. View ticket statuses again to verify trigger effect.
SELECT ticket_id, trip_id, ticket_status FROM tickets WHERE trip_id = 2;

USE FinalProject;
GO

CREATE TRIGGER t_prevent_booking_past_trips
ON tickets
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if any tickets attempting to be inserted belong to past trips.
    -- We define this as: Current system time > trip scheduled departure time.
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN trips t ON i.trip_id = t.trip_id
        WHERE GETDATE() > t.trip_scheduled_departure_time
    )
    BEGIN
        -- If exists, throw error and rollback (Since it's an INSTEAD OF trigger, not performing the actual insert is equivalent to blocking).
        RAISERROR ('Cannot book tickets for a trip that has already departed.', 16, 1);
        -- ROLLBACK here is optional because INSTEAD OF trigger itself replaces the insert operation,
        -- but if this insert is part of a larger transaction, ROLLBACK is necessary. Added for safety.
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
        RETURN;
    END

    INSERT INTO tickets (trip_id, ticket_price, ticket_status, order_id, passenger_id, ticket_seat_number)
    SELECT trip_id, ticket_price, ticket_status, order_id, passenger_id, ticket_seat_number
    FROM inserted;
END;
GO

-- TESTING trigger 2: t_prevent_booking_past_trips

-- A. Prepare test data: Insert an old trip.
INSERT INTO trips (conductor_id, train_id, start_station_id, end_station_id, trip_scheduled_departure_time, trip_scheduled_arrival_time, trip_distance_miles)
VALUES (1, 1, 1, 2, '2023-01-01 10:00:00', '2023-01-01 12:00:00', 100.00);

-- Get the ID of the old trip just inserted (Assuming it's the current max ID).
DECLARE @OldTripID INT = SCOPE_IDENTITY();

-- B. Test trigger: Attempt to insert a ticket for this old trip.
-- expect: This insertion should fail and display an error message.
BEGIN TRY
    INSERT INTO tickets (trip_id, ticket_price, ticket_status, order_id, passenger_id)
    VALUES (@OldTripID, 50.00, 'Booked', 1, 1);
END TRY
BEGIN CATCH
    PRINT 'Insertion failed as expected. Error Message: ' + ERROR_MESSAGE();
END CATCH

-- C. Verification: Confirm ticket was not inserted.
SELECT * FROM tickets WHERE trip_id = @OldTripID;
