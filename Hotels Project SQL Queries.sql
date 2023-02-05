--Creating DimRooms dimension

  Create Table DimRooms
  (RoomSK int identity(1,1),
  RoomID int,
  Price_day int,
  Capacity int,
  RoomType nvarchar(50),
  Prefix Nvarchar(50)
  Constraint DimRooms_pk Primary key(RoomSK))


  Insert into dbo.DimRooms
  Select Distinct 
   [id]
      ,[price_day]
      ,[capacity]
      ,[type] as RoomType
      ,[prefix]
  from [dbo].[Rooms]

    Select * from dimrooms


	-- create DimClient



Create Table DimClient
	(ClientSk int identity(1,1),
	Client_name nvarchar(50)
	Constraint Client_pk Primary key(ClientSk)
	)


Insert into DimClient
Select distinct Client_name  
FROM   Requests

alter table DimClient
Add ClientID as ClientSk + 0

Select * from DimClient



--DimRequest_Type

Create Table DimRequest_Type
	(ReqTypeSk int identity(1,1),
	Request_Type nvarchar(50)
	Constraint ReqType_pk Primary key(ReqTypeSk)
	)


Insert into DimRequest_Type
select distinct request_type 
from Requests


alter table DimRequest_Type
Add ReqTypeID as ReqTypeSk + 0

Select * from DimRequest_Type



Create table dbo.dimDate
(
 datekey int,
 CalendarDate date,
 CalendarYear int,
 CalendarQuarter nvarchar (2),
 CalendarMonth int,
 CalendarEnglishName nvarchar(50),
 CalendarDay int,
 CalendarWeek int,
 constraint Hotel_dimDate_sk primary key(datekey)
)

set nocount on
declare @StartDate date = '2000-01-01'
declare @EndDate date = '2040-12-31'
while @StartDate<@EndDate
begin
	insert into dbo.dimDate 
	select DateKey = convert(char(8), @StartDate, 112),
		   CalendarDate = convert(char(10), @StartDate,110),
		   CalendarYear = Datepart(yy, @StartDate),
		   CalendarQuarter = Datepart(qq, @StartDate),
		   CalendarMonth = Datepart(mm, @StartDate),
		   CalendarEnglishMonth = datename(month, @startdate),
		   CalendarDay = DATEPART(dd, @StartDate),
		   CalendarWeek = DATEPART(ww, @StartDate)
		  
	set @StartDate = dateadd (dd, 1, @StartDate)
end;

select * from dimdate
--------------------------------------------------------------------------------------------

CREATE TABLE [dbo].[DimTime](
    [TimeSk] [int] IDENTITY(1,1), 
    [Time] [time](0) NULL,
    [Hour] [int] NULL,
    [Minute] [int] NULL,
    [MilitaryHour] int NOT null,
    [MilitaryMinute] int NOT null,
    [AMPM] [varchar](2) NOT NULL,
    [Notation12] [varchar](10) NULL,
    [Notation24] [varchar](10) NULL
	Constraint Hotel_Time_PK primary key  (TimeSk)
);

 
-- Create a time and a counter variable for the loop
Set nocount on
DECLARE @Time as time;
SET @Time = '0:00';
 
DECLARE @counter as int;
SET @counter = 0;
 
 
-- Loop 1440 times (24hours * 60minutes)
WHILE @counter < 1440
BEGIN
 
    INSERT INTO DimTime ([Time]
                       , [Hour]
                       , [Minute]
                       , [MilitaryHour]
                       , [MilitaryMinute]
                       , [AMPM]
                       , [Notation12]
                       , [Notation24])
                VALUES (@Time
                       , DATEPART(Hour, @Time) + 1
                       , DATEPART(Minute, @Time) + 1
                       , DATEPART(Hour, @Time)
                       , DATEPART(Minute, @Time)
                       , CASE WHEN (DATEPART(Hour, @Time) < 12) THEN 'AM' ELSE 'PM' END
                       , CONVERT(varchar(10), @Time,100)
                       , CAST(@Time as varchar(5))
                       );
 
    -- Raise time with one minute
    SET @Time = DATEADD(minute, 1, @Time);
 
    -- Raise counter by one
    set @counter = @counter + 1;
END

Select * From DimTime



 ----Creating Fact and dimensions for food Orders


	Create Table DimRoomNumber
	(RoomNumberSk int identity(1,1),
	RoomNumber nvarchar(30)
	Constraint RoomType_pk Primary key(RoomNumberSk)
	)


Insert into DimRoomNumber
select u.room as RoomNumber from
	(Select  room From dbo.Bookings
	Union
	Select  bill_room From dbo.FoodOrders
	Union
	Select dest_room From dbo.FoodOrders) u

alter table DimRoomNumber
add  RoomNumberID as  RoomNumberSK + 0

Select * from DimRoomNumber


----To create Fact_Booking_Request

Create Table Fact_Booking_Request 
	(Fact_RequestSk int Identity(1,1),
	Request_ID int,
	ClientSk int,
	RoomSk int,
	ReqTypeSk int,
	Start_Date_sk int,
	End_Date_sk int,
	NoOfAdults int,
	NoOfChildren int,
	RoomNumberSk int,
	Constraint Fact_Request_pk primary key(Fact_RequestSk),
	Constraint ClientSk_fk Foreign key(ClientSk) references DimClient(ClientSk),
	Constraint RoomSk_fk Foreign key(RoomSk) references DimRooms(RoomSk),
	Constraint ReqTypeSk_fk Foreign key(ReqTypeSk) references DimRequest_Type(ReqTypeSk),
	Constraint RoomNo_fk Foreign key(RoomNumberSk) references DimRoomNumber(RoomNumberSk),
	Constraint StartDate_fk Foreign key (Start_Date_sk) References DimDate(Datekey),
	Constraint EndDate_fk Foreign key (End_Date_sk) References DimDate(Datekey),
	)


Insert into Fact_Booking_Request
SELECT 
	r.request_id,
	c.ClientSk,
	dr.RoomSK,
	rt.ReqTypeSk, 
	dd.datekey as Start_date_Sk, 
	da.datekey as end_date_Sk, 
	r.adults as NoOfAdults, 
	r.children as NoOfChildren, 
	rn.RoomNumberSk
FROM Requests r
left join DimClient c on r.client_name = c.Client_name
left join DimRooms dr on r.room_type = dr.RoomType
left join DimRequest_Type rt on r.request_type = rt.Request_Type
left join bookings b on r.request_id = b.request_id
left join DimRoomNumber rn on rn.RoomNumber = b.room
left join dimDate dd on dd.CalendarDate = r.start_date
left join dimDate da on da.CalendarDate = r.end_date



select * from Fact_Booking_Request



	
  --Creating DimMenu
Insert into dbo.DimMenu
Select distinct id as MenuID, 
				[name],
	            price,
	            category 
FROM Menu


Create Table DimMenu
	(MenuSk int Identity(1,1),
	MenuID int,
	Name Nvarchar(50),
	Price Float,
	Category Nvarchar(50),
Constraint DimMenu_pk Primary key(MenuSk)
);
  
select * from DimMenu
select * from Fact_FoodOrders
	
	--Fact Food orders
Insert into Fact_FoodOrders
Select 
	dr.RoomNumberSk as DestRoomSk,
	b.RoomNumberSk as BillRoomSk,
	d.datekey as OrderDate,
	dt.TimeSk as OrderTimeSk,
	f.orders,
	m.MenuSk
FROM Food f
Left join DimMenu M on f.menu_id = M.MenuID
Left Join dimDate d on d.CalendarDate = f.[date]
Left join DimRoomNumber dr on dr.RoomNumber = f.dest_room
Left join DimRoomNumber b on b.RoomNumber = f.bill_room
Left join DimTime dt on f.Time = dt.Time

select * from Fact_FoodOrders

select * from [dbo].[Food_Orders]

Create Table Fact_FoodOrders 
	(FoodSk int Identity(1,1),
	DestRoomSk int,
	BillRoomSk int,
	OrderDatesk int,
	OrderTimeSk int,
	Orders int,
	MenuSk int,
Constraint Fact_FoodSk_pk Primary key(FoodSk),
Constraint DimMenu_fk Foreign key (MenuSk) References DimMenu(MenuSk),
Constraint Orderdate_fk Foreign key (OrderDateSk) References DimDate(Datekey),
Constraint DestRoom_fk Foreign key (DestRoomSk) References DimRoomNumber(RoomNumberSk),
Constraint BillRoom_fk Foreign key (BillRoomSk) References DimRoomNumber(RoomNumberSk),
Constraint DimTime_fk Foreign key (OrderTimeSk) References DimTime(TimeSk)
)

Alter Table Fact_FoodOrders
Add Constraint DimTime_fk Foreign key (OrderTimeSk) References DimTime(TimeSk)

drop table Fact_FoodOrders