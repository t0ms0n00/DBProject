USE [master]
GO
/****** Object:  Database [u_boron]    Script Date: 2021-01-20 23:12:01 ******/
CREATE DATABASE [u_boron]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'u_boron', FILENAME = N'/var/opt/mssql/data/u_boron.mdf' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'u_boron_log', FILENAME = N'/var/opt/mssql/data/u_boron_log.ldf' , SIZE = 66048KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [u_boron] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [u_boron].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [u_boron] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [u_boron] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [u_boron] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [u_boron] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [u_boron] SET ARITHABORT OFF 
GO
ALTER DATABASE [u_boron] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [u_boron] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [u_boron] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [u_boron] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [u_boron] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [u_boron] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [u_boron] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [u_boron] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [u_boron] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [u_boron] SET  ENABLE_BROKER 
GO
ALTER DATABASE [u_boron] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [u_boron] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [u_boron] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [u_boron] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [u_boron] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [u_boron] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [u_boron] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [u_boron] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [u_boron] SET  MULTI_USER 
GO
ALTER DATABASE [u_boron] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [u_boron] SET DB_CHAINING OFF 
GO
ALTER DATABASE [u_boron] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [u_boron] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [u_boron] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [u_boron] SET QUERY_STORE = OFF
GO
USE [u_boron]
GO
/****** Object:  UserDefinedFunction [dbo].[Data_Rezerwacji]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Data_Rezerwacji]
(
	@id_rezerwacji int
)
RETURNS date
AS
BEGIN
	RETURN(
		SELECT Data_rezerwacji FROM Rezerwacje
		WHERE @id_rezerwacji=ID_rezerwacji
	)

END
GO
/****** Object:  UserDefinedFunction [dbo].[Generuj_Fakture_Miesieczna]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Generuj_Fakture_Miesieczna]
(
	@id_klienta int
)
RETURNS 
@faktura TABLE 
(
	-- Add the column definitions for the TABLE variable here
	Szczegol VARCHAR(150), 
	Wartosc money
)
AS
BEGIN
	DECLARE @nazwa_firmy varchar(50) = (SELECT Nazwa_firmy FROM Klienci_Biz WHERE ID_klienta=@id_klienta)
	DECLARE @nip varchar(10) = (SELECT NIP FROM Klienci_Biz WHERE ID_klienta=@id_klienta)
	DECLARE @ulica varchar(50) = (SELECT Ulica FROM Klienci_Biz WHERE ID_klienta=@id_klienta)
	DECLARE @kod_pocztowy varchar(6) = (SELECT Kod_pocztowy FROM Klienci_Biz WHERE ID_klienta=@id_klienta)
	DECLARE @miasto varchar(50) = (SELECT Nazwa_miasta FROM Miasta 
	INNER JOIN Klienci_Biz ON Klienci_Biz.ID_miasta=Miasta.ID_miasta WHERE @id_klienta=ID_klienta)
	DECLARE @panstwo varchar(50) = (SELECT Panstwa.Nazwa FROM Panstwa INNER JOIN Miasta ON Miasta.ID_państwa=Panstwa.ID_państwa
	INNER JOIN Klienci_Biz ON Klienci_Biz.ID_miasta=Miasta.ID_miasta WHERE @id_klienta=ID_klienta)
	DECLARE @adres varchar(100) = CONCAT(@ulica,', ',@kod_pocztowy,' ',@miasto,', ',@panstwo)
	INSERT INTO @faktura(Szczegol,Wartosc)
	VALUES (CONCAT('Faktura miesieczna dla klienta: ', @nazwa_firmy),NULL)
	INSERT INTO @faktura(Szczegol,Wartosc)
	VALUES (CONCAT('NIP: ',@nip),NULL)
	INSERT INTO @faktura(Szczegol,Wartosc)
	VALUES (CONCAT('Adres: ',@adres),NULL)
	INSERT INTO @faktura(Szczegol,Wartosc)
	VALUES ('',NULL)
	DECLARE @sumaryczna_wart money = 0
	DECLARE iter CURSOR
	FOR
		SELECT ID_zamówienia FROM Zamówienia
		WHERE ID_klienta=@id_klienta AND DATEDIFF(day,Data_zamówienia,GETDATE())<=30
	DECLARE @id_zamowienia int
	OPEN iter
	FETCH NEXT FROM iter INTO @id_zamowienia
	WHILE @@FETCH_STATUS=0
	BEGIN
		INSERT INTO @faktura(Szczegol,Wartosc)
		VALUES ('',NULL)
		DECLARE @data_zlozenia date =(SELECT Data_zamówienia FROM Zamówienia WHERE @id_zamowienia=ID_zamówienia)
		INSERT INTO @faktura(Szczegol,Wartosc) VALUES
		(CONCAT('Zamowienie: ', @id_zamowienia,' zlozone dnia: ',@data_zlozenia),NULL)
		DECLARE danie CURSOR
		FOR
			SELECT ID_pozycji FROM Szczegóły_Zamówień
			WHERE ID_zamówienia=@id_zamowienia
		DECLARE @id_pozycji int
		OPEN danie
		FETCH NEXT FROM danie INTO @id_pozycji
		WHILE @@FETCH_STATUS=0
		BEGIN
			DECLARE @nazwa_dania varchar(50) =(SELECT Nazwa_dania FROM Menu m INNER JOIN Dania d ON d.ID_dania=m.ID_dania WHERE m.ID_pozycji=@id_pozycji)
			DECLARE @ilosc int =(SELECT Ilość FROM Szczegóły_Zamówień WHERE @id_zamowienia=ID_zamówienia AND ID_pozycji=@id_pozycji)
			DECLARE @cena money =(SELECT Cena_jednostkowa FROM Szczegóły_Zamówień WHERE @id_zamowienia=ID_zamówienia AND ID_pozycji=@id_pozycji)
			INSERT INTO @faktura(Szczegol,Wartosc)
			VALUES(CONCAT('Zamówione danie:', @nazwa_dania, ',   Ilość: ', @ilosc, ',   Cena jednostkowa:',
					@cena),@cena*@ilosc)
			FETCH NEXT FROM danie INTO @id_pozycji
		END
		CLOSE danie
		DEALLOCATE danie
		DECLARE @laczna_wart_zam money = dbo.Wartosc_Zamowienia_Z_Rabatem(@id_zamowienia)
		INSERT INTO @faktura(Szczegol,Wartosc)
		VALUES('Laczna kwota za zamowienie: ',@laczna_wart_zam)
		SET @sumaryczna_wart=@sumaryczna_wart+@laczna_wart_zam
		FETCH NEXT FROM iter INTO @id_zamowienia
	END 
	CLOSE iter
	DEALLOCATE iter
	INSERT INTO @faktura(Szczegol,Wartosc)
	VALUES ('',NULL)
	INSERT INTO @faktura(Szczegol,Wartosc)
	VALUES('Laczna kwota za wszystkie zamowienia: ',@sumaryczna_wart)
	RETURN 
END
GO
/****** Object:  UserDefinedFunction [dbo].[Ilosc_Zamowien_Powyzej_Kwoty]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Ilosc_Zamowien_Powyzej_Kwoty]
(
	@id_restauracji int,
	@id_klienta int,
	@kwota money
)
RETURNS int
AS
BEGIN
	RETURN (
		SELECT COUNT(liczba_zam) FROM 
		(
			SELECT COUNT(DISTINCT z.ID_zamówienia) as liczba_zam FROM Zamówienia z
			INNER JOIN Szczegóły_Zamówień sz ON sz.ID_zamówienia=z.ID_zamówienia
			WHERE z.ID_klienta=@id_klienta AND z.Pracownik_obsługujący IN (SELECT ID_pracownika FROM Obsluga WHERE ID_Restauracji=@id_restauracji)
			GROUP BY z.ID_zamówienia
			HAVING sum(sz.Ilość*sz.Cena_jednostkowa)>@kwota
		) as zamowienia
	)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Liczba_Wolnych_Miejsc]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Liczba_Wolnych_Miejsc]
(
	@id_restauracji int,
	@data_rezerwacji date
)
RETURNS int
AS
BEGIN
	DECLARE @wszystkie_miejsca int = (SELECT SUM(o.Liczba_miejsc)
		FROM Obostrzenia o
		INNER JOIN Stoliki s ON s.ID_stolika=o.ID_stolika
		WHERE s.ID_Restauracji=@id_restauracji AND
		o.Data_wprowadzenia=(SELECT max(o2.Data_wprowadzenia) FROM Obostrzenia o2
							WHERE o2.ID_stolika=o.ID_stolika)
		)
	DECLARE @zajete_miejsca int =(SELECT SUM(o.Liczba_miejsc)
		FROM Obostrzenia o
		INNER JOIN Szczegóły_Rezerwacji sr ON sr.ID_obostrzenia=o.ID_Obostrzenia
		INNER JOIN Rezerwacje r on r.ID_rezerwacji=sr.ID_rezerwacji
		WHERE r.ID_Restauracji=@id_restauracji AND DATEDIFF(day,r.Data_rezerwacji,@data_rezerwacji)=0)
	RETURN (@wszystkie_miejsca-@zajete_miejsca)

END
GO
/****** Object:  UserDefinedFunction [dbo].[Nalicz_Rabat_Firm_Kwartalny]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Nalicz_Rabat_Firm_Kwartalny]
(
	@id_restauracji int,
	@id_klienta int
)
RETURNS float
AS
BEGIN
	DECLARE @id_rabatu int = (
		SELECT TOP 1 r.ID_rabatu FROM Rabaty r
		INNER JOIN Aktualnie_Przyznane_Rabaty a ON a.ID_rabatu=r.ID_rabatu AND a.ID_klienta=@id_klienta
		AND r.ID_rabatu NOT IN 
		(SELECT ID_rabatu FROM Rabaty_Ind_Jednorazowe)
		AND r.ID_rabatu NOT IN 
		(SELECT ID_rabatu FROM Rabaty_Ind_Stale)
		AND r.ID_rabatu NOT IN 
		(SELECT ID_rabatu FROM Rabaty_Firm_Miesiac)
		WHERE r.ID_Restauracji=@id_restauracji AND r.Data_zdjęcia IS NULL
	)
	
	IF @id_rabatu IS NULL
	BEGIN
		RETURN 0
	END
	
	DECLARE @wysokosc float = (SELECT Wysokosc_jedn FROM Rabaty WHERE @id_rabatu=ID_rabatu)

	RETURN @wysokosc
END
GO
/****** Object:  UserDefinedFunction [dbo].[Nalicz_Rabat_Firm_Miesieczny]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Nalicz_Rabat_Firm_Miesieczny]
(
	@id_restauracji int,
	@id_klienta int
)
RETURNS float
AS
BEGIN
	DECLARE @id_rabatu int = (
		SELECT TOP 1 r.ID_rabatu FROM Rabaty r
		INNER JOIN Aktualnie_Przyznane_Rabaty a ON a.ID_rabatu=r.ID_rabatu AND a.ID_klienta=@id_klienta
		INNER JOIN Rabaty_Firm_Miesiac rf ON rf.ID_rabatu=r.ID_rabatu
		WHERE r.ID_Restauracji=@id_restauracji AND r.Data_zdjęcia IS NULL
	)
	
	IF @id_rabatu IS NULL
	BEGIN
		RETURN 0
	END
	
	DECLARE @data_przyznania date = (SELECT Data_przyznania FROM Aktualnie_Przyznane_Rabaty WHERE @id_rabatu=ID_rabatu AND ID_klienta=@id_klienta)

	DECLARE @wysokosc float = (SELECT Wysokosc_jedn FROM Rabaty WHERE @id_rabatu=ID_rabatu)

	DECLARE @max_rabat float = (SELECT Max_rabat FROM Rabaty_Firm_Miesiac WHERE @id_rabatu=ID_rabatu)

	IF DATEDIFF(month,@data_przyznania,GETDATE())*@wysokosc<@max_rabat
	BEGIN 
		RETURN DATEDIFF(month,@data_przyznania,GETDATE())*@wysokosc
	END
	RETURN @max_rabat
END
GO
/****** Object:  UserDefinedFunction [dbo].[Nalicz_Rabat_Ind_Jednorazowy]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Nalicz_Rabat_Ind_Jednorazowy]
(
	@id_restauracji int,
	@id_klienta int
)
RETURNS float
AS
BEGIN
	DECLARE @id_rabatu int = (
		SELECT TOP 1 r.ID_rabatu FROM Rabaty r
		INNER JOIN Aktualnie_Przyznane_Rabaty a ON a.ID_rabatu=r.ID_rabatu AND a.ID_klienta=@id_klienta
		INNER JOIN Rabaty_Ind_Jednorazowe rj ON rj.ID_rabatu=r.ID_rabatu
		WHERE r.ID_Restauracji=@id_restauracji AND r.Data_zdjęcia IS NULL
	)
	
	IF @id_rabatu IS NULL
	BEGIN
		RETURN 0
	END
	
	DECLARE @kwota money = (SELECT Wymagana_kwota FROM Rabaty WHERE ID_rabatu=@id_rabatu)

	IF GETDATE() NOT BETWEEN (SELECT Data_przyznania FROM Aktualnie_Przyznane_Rabaty WHERE ID_klienta=@id_klienta AND @id_rabatu=ID_rabatu)
	AND (SELECT Data_wygaśnięcia FROM Aktualnie_Przyznane_Rabaty WHERE ID_klienta=@id_klienta AND @id_rabatu=ID_rabatu)
	BEGIN
		RETURN 0
	END

	DECLARE @laczna_wart_zam money = (SELECT SUM(sz.Ilość*sz.Cena_jednostkowa) FROM Szczegóły_Zamówień sz
		INNER JOIN Zamówienia z ON z.ID_zamówienia=sz.ID_zamówienia
		WHERE @id_klienta=z.ID_klienta)

	IF @laczna_wart_zam<@kwota
	BEGIN
		RETURN 0
	END

	RETURN (SELECT Wysokosc_jedn FROM Rabaty WHERE @id_rabatu=ID_rabatu)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Nalicz_Rabat_Ind_Staly]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Nalicz_Rabat_Ind_Staly]
(
	@id_restauracji int,
	@id_klienta int
)
RETURNS float
AS
BEGIN
	DECLARE @id_rabatu int = (
		SELECT TOP 1 r.ID_rabatu FROM Rabaty r
		INNER JOIN Aktualnie_Przyznane_Rabaty a ON a.ID_rabatu=r.ID_rabatu AND a.ID_klienta=@id_klienta
		INNER JOIN Rabaty_Ind_Stale rs ON rs.ID_rabatu=r.ID_rabatu
		WHERE r.ID_Restauracji=@id_restauracji AND r.Data_zdjęcia IS NULL
	)
	
	IF @id_rabatu IS NULL
	BEGIN
		RETURN 0
	END
	
	DECLARE @kwota money = (SELECT Wymagana_kwota FROM Rabaty WHERE ID_rabatu=@id_rabatu)

	DECLARE @ilosc_powyzej_kwoty int =  dbo.Ilosc_Zamowien_Powyzej_Kwoty(@id_restauracji,@id_klienta,@kwota)

	DECLARE @liczba_zamowien int = (SELECT Liczba_zamowien FROM Rabaty_Ind_Stale WHERE ID_rabatu=@id_rabatu)

	RETURN @ilosc_powyzej_kwoty/@liczba_zamowien*(SELECT Wysokosc_jedn FROM Rabaty WHERE ID_rabatu=@id_rabatu)

END
GO
/****** Object:  UserDefinedFunction [dbo].[Ostatnie_Usuniecie_Z_Menu]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Ostatnie_Usuniecie_Z_Menu]
(
	@id_dania int,
	@id_restauracji int
)
RETURNS date
AS
BEGIN
	RETURN (SELECT TOP 1 Data_zdjęcia FROM Menu WHERE @id_dania=ID_dania AND @id_restauracji=ID_restauracji ORDER BY Data_zdjęcia DESC)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Pobierz_Numer_Stolika]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Pobierz_Numer_Stolika]
(
	@id_restauracji int,
	@data_rezerwacji date
)
RETURNS int
AS
BEGIN
	RETURN (SELECT TOP 1 o.ID_stolika FROM Obostrzenia o
			INNER JOIN Stoliki s ON s.ID_stolika=o.ID_stolika
			INNER JOIN Restauracje r ON r.ID_restauracji=s.ID_Restauracji
			WHERE r.ID_restauracji=@id_restauracji AND s.ID_stolika 
			NOT IN(
				SELECT o2.ID_stolika FROM Szczegóły_Rezerwacji sr2
				INNER JOIN Obostrzenia o2 ON sr2.ID_obostrzenia=o2.ID_Obostrzenia
				INNER JOIN Rezerwacje r2 ON r2.ID_rezerwacji=sr2.ID_rezerwacji
				WHERE r2.ID_Restauracji=@id_restauracji
				AND DATEDIFF(day,r2.Data_rezerwacji,@data_rezerwacji)=0
			)
			AND(
			SELECT TOP 1 o3.Liczba_miejsc FROM Obostrzenia o3
			WHERE o3.ID_Obostrzenia=o.ID_Obostrzenia
			ORDER BY Data_wprowadzenia DESC)>0
			ORDER BY Data_wprowadzenia DESC
			)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Pobierz_Obostrzenie_Do_Rezerwacji]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Pobierz_Obostrzenie_Do_Rezerwacji]
(
	@id_restauracji int,
	@data_rezerwacji date
)
RETURNS int
AS
BEGIN
	RETURN (
	SELECT TOP 1 o.ID_Obostrzenia
	FROM Obostrzenia o
	INNER JOIN Stoliki s ON s.ID_stolika=o.ID_stolika
	WHERE s.ID_Restauracji=@id_restauracji AND
	o.Data_wprowadzenia=(SELECT max(o2.Data_wprowadzenia) FROM Obostrzenia o2
						WHERE o2.ID_stolika=o.ID_stolika)
	AND ID_Obostrzenia NOT IN
	(SELECT o.ID_Obostrzenia
		FROM Obostrzenia o
		INNER JOIN Szczegóły_Rezerwacji sr ON sr.ID_obostrzenia=o.ID_Obostrzenia
		INNER JOIN Rezerwacje r on r.ID_rezerwacji=sr.ID_rezerwacji
		WHERE r.ID_Restauracji=@id_restauracji AND DATEDIFF(day,r.Data_rezerwacji,@data_rezerwacji)=0)
	)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Wartosc_Zamowienia_Z_Rabatem]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[Wartosc_Zamowienia_Z_Rabatem]
(
	@id_zamowienia int
)
RETURNS money
AS
BEGIN
	RETURN (SELECT SUM(Ilość*Cena_jednostkowa) 
			FROM Szczegóły_Zamówień 
			WHERE ID_zamówienia=@id_zamowienia
)
END
GO
/****** Object:  Table [dbo].[Polprodukty]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Polprodukty](
	[ID_półproduktu] [int] IDENTITY(1,1) NOT NULL,
	[Nazwa] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Półprodukty] PRIMARY KEY CLUSTERED 
(
	[ID_półproduktu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [Un_Półprodukty_Nazwa] UNIQUE NONCLUSTERED 
(
	[Nazwa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Restauracje]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Restauracje](
	[ID_restauracji] [int] IDENTITY(1,1) NOT NULL,
	[Nazwa] [varchar](50) NOT NULL,
	[Ulica] [varchar](50) NOT NULL,
	[Miasto] [int] NOT NULL,
 CONSTRAINT [PK_Restauracje] PRIMARY KEY CLUSTERED 
(
	[ID_restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Przepisy]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Przepisy](
	[ID_dania] [int] NOT NULL,
	[ID_półproduktu] [int] NOT NULL,
	[Potrzebna_ilość] [float] NOT NULL,
 CONSTRAINT [PK_Przepisy] PRIMARY KEY CLUSTERED 
(
	[ID_dania] ASC,
	[ID_półproduktu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Dania]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dania](
	[ID_dania] [int] IDENTITY(1,1) NOT NULL,
	[Nazwa_dania] [varchar](50) NOT NULL,
	[Cena_dania] [money] NOT NULL,
	[Kategoria] [int] NOT NULL,
	[Opis_dania] [varchar](255) NULL,
 CONSTRAINT [PK_Dania] PRIMARY KEY CLUSTERED 
(
	[ID_dania] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Menu]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Menu](
	[ID_dania] [int] NOT NULL,
	[Data_wprowadzenia] [date] NOT NULL,
	[Data_zdjęcia] [date] NULL,
	[ID_pozycji] [int] IDENTITY(1,1) NOT NULL,
	[ID_restauracji] [int] NOT NULL,
 CONSTRAINT [PK_Menu_1] PRIMARY KEY CLUSTERED 
(
	[ID_pozycji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Stan_Magazynowy]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stan_Magazynowy](
	[ID_półproduktu] [int] NOT NULL,
	[ID_restauracji] [int] NOT NULL,
	[Stan_magazynowy] [float] NOT NULL,
 CONSTRAINT [PK_StanMagazynowy] PRIMARY KEY CLUSTERED 
(
	[ID_półproduktu] ASC,
	[ID_restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_Pozycje_Niemozliwe_Do_Stworzenia]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Pozycje_Niemozliwe_Do_Stworzenia]
AS
SELECT dbo.Restauracje.Nazwa, dbo.Dania.Nazwa_dania, dbo.Polprodukty.Nazwa AS Polprodukt, dbo.Przepisy.Potrzebna_ilość, dbo.Stan_Magazynowy.Stan_magazynowy
FROM     dbo.Dania INNER JOIN
                  dbo.Menu ON dbo.Dania.ID_dania = dbo.Menu.ID_dania INNER JOIN
                  dbo.Przepisy ON dbo.Dania.ID_dania = dbo.Przepisy.ID_dania INNER JOIN
                  dbo.Polprodukty ON dbo.Przepisy.ID_półproduktu = dbo.Polprodukty.ID_półproduktu INNER JOIN
                  dbo.Restauracje ON dbo.Menu.ID_restauracji = dbo.Restauracje.ID_restauracji INNER JOIN
                  dbo.Stan_Magazynowy ON dbo.Polprodukty.ID_półproduktu = dbo.Stan_Magazynowy.ID_półproduktu AND dbo.Restauracje.ID_restauracji = dbo.Stan_Magazynowy.ID_restauracji AND 
                  dbo.Przepisy.Potrzebna_ilość > dbo.Stan_Magazynowy.Stan_magazynowy
WHERE  (dbo.Menu.Data_zdjęcia IS NULL)
GO
/****** Object:  UserDefinedFunction [dbo].[Przepis]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Przepis] 
(	
	@id_dania int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT po.Nazwa,p.Potrzebna_ilość
	FROM Przepisy p
	INNER JOIN Polprodukty po ON po.ID_półproduktu=p.ID_półproduktu
	WHERE p.ID_dania=@id_dania
)
GO
/****** Object:  UserDefinedFunction [dbo].[Stan_Magazynu]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Stan_Magazynu]
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT p.Nazwa,s.Stan_magazynowy
	FROM Stan_Magazynowy s
	INNER JOIN Polprodukty p ON p.ID_półproduktu=s.ID_półproduktu
	WHERE s.ID_restauracji=@id_restauracji
)
GO
/****** Object:  Table [dbo].[Miasta]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Miasta](
	[ID_miasta] [int] IDENTITY(1,1) NOT NULL,
	[Nazwa_miasta] [varchar](50) NOT NULL,
	[ID_państwa] [int] NOT NULL,
 CONSTRAINT [PK_Miasta] PRIMARY KEY CLUSTERED 
(
	[ID_miasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_Braki_W_Magazynie]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Braki_W_Magazynie]
AS
SELECT dbo.Restauracje.Nazwa, dbo.Restauracje.Ulica, dbo.Miasta.Nazwa_miasta, dbo.Polprodukty.Nazwa AS Polprodukt, dbo.Stan_Magazynowy.Stan_magazynowy
FROM     dbo.Restauracje INNER JOIN
                  dbo.Stan_Magazynowy ON dbo.Restauracje.ID_restauracji = dbo.Stan_Magazynowy.ID_restauracji INNER JOIN
                  dbo.Miasta ON dbo.Restauracje.Miasto = dbo.Miasta.ID_miasta INNER JOIN
                  dbo.Polprodukty ON dbo.Stan_Magazynowy.ID_półproduktu = dbo.Polprodukty.ID_półproduktu
WHERE  (dbo.Stan_Magazynowy.Stan_magazynowy = 0)
GO
/****** Object:  Table [dbo].[Szczegóły_Zamówień]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Szczegóły_Zamówień](
	[ID_zamówienia] [int] NOT NULL,
	[ID_pozycji] [int] NOT NULL,
	[Cena_jednostkowa] [money] NOT NULL,
	[Ilość] [int] NOT NULL,
 CONSTRAINT [PK_Szczegóły_Zamówień] PRIMARY KEY CLUSTERED 
(
	[ID_zamówienia] ASC,
	[ID_pozycji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_Najpopularniejsze_Dania]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Najpopularniejsze_Dania]
AS
SELECT TOP (20) PERCENT dbo.Dania.Nazwa_dania, dbo.Dania.Cena_dania, SUM(dbo.Szczegóły_Zamówień.Ilość) AS Liczba_zamówionych_jednostek
FROM     dbo.Menu INNER JOIN
                  dbo.Dania ON dbo.Menu.ID_dania = dbo.Dania.ID_dania INNER JOIN
                  dbo.Szczegóły_Zamówień ON dbo.Menu.ID_pozycji = dbo.Szczegóły_Zamówień.ID_pozycji
GROUP BY dbo.Dania.Nazwa_dania, dbo.Dania.Cena_dania, dbo.Dania.ID_dania
ORDER BY Liczba_zamówionych_jednostek DESC
GO
/****** Object:  Table [dbo].[Zamówienia]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Zamówienia](
	[ID_zamówienia] [int] IDENTITY(1,1) NOT NULL,
	[ID_klienta] [int] NOT NULL,
	[Data_zamówienia] [datetime] NOT NULL,
	[Data_odbioru] [datetime] NOT NULL,
	[Na_wynos] [varchar](1) NOT NULL,
	[Pracownik_obsługujący] [int] NOT NULL,
 CONSTRAINT [PK_Zamówienia] PRIMARY KEY CLUSTERED 
(
	[ID_zamówienia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Klienci]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Klienci](
	[ID_klienta] [int] IDENTITY(1,1) NOT NULL,
	[Telefon_kontaktowy] [varchar](9) NOT NULL,
	[Email] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Klienci] PRIMARY KEY CLUSTERED 
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [Un_Klienci_Email] UNIQUE NONCLUSTERED 
(
	[Email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_Klienci_Wydatki]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Klienci_Wydatki]
AS
SELECT dbo.Klienci.ID_klienta, SUM(dbo.Szczegóły_Zamówień.Ilość * dbo.Szczegóły_Zamówień.Cena_jednostkowa) AS Łączna_wart_zam
FROM     dbo.Klienci INNER JOIN
                  dbo.Zamówienia ON dbo.Klienci.ID_klienta = dbo.Zamówienia.ID_klienta INNER JOIN
                  dbo.Szczegóły_Zamówień ON dbo.Zamówienia.ID_zamówienia = dbo.Szczegóły_Zamówień.ID_zamówienia
GROUP BY dbo.Klienci.ID_klienta
GO
/****** Object:  Table [dbo].[Klienci_Biz]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Klienci_Biz](
	[ID_klienta] [int] NOT NULL,
	[Nazwa_firmy] [varchar](50) NOT NULL,
	[NIP] [varchar](10) NOT NULL,
	[Ulica] [varchar](50) NOT NULL,
	[Kod_pocztowy] [varchar](6) NOT NULL,
	[ID_miasta] [int] NOT NULL,
 CONSTRAINT [PK_Klienci_Biz] PRIMARY KEY CLUSTERED 
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [Un_Klienci_Biz_NIP] UNIQUE NONCLUSTERED 
(
	[NIP] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Klienci_Ind]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Klienci_Ind](
	[ID_klienta] [int] NOT NULL,
	[Imię] [varchar](30) NOT NULL,
	[Nazwisko] [varchar](30) NOT NULL,
 CONSTRAINT [PK_Klienci_Ind] PRIMARY KEY CLUSTERED 
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Pracownicy_Firm]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pracownicy_Firm](
	[ID_firmy] [int] NOT NULL,
	[ID_pracownika] [int] NOT NULL,
 CONSTRAINT [PK_Pracownicy_Firm] PRIMARY KEY CLUSTERED 
(
	[ID_firmy] ASC,
	[ID_pracownika] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[V_Pracownicy_Firm]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Pracownicy_Firm]
AS
SELECT dbo.Klienci_Biz.Nazwa_firmy, dbo.Klienci_Ind.Imię, dbo.Klienci_Ind.Nazwisko
FROM     dbo.Klienci_Biz INNER JOIN
                  dbo.Pracownicy_Firm ON dbo.Klienci_Biz.ID_klienta = dbo.Pracownicy_Firm.ID_firmy INNER JOIN
                  dbo.Klienci_Ind ON dbo.Pracownicy_Firm.ID_pracownika = dbo.Klienci_Ind.ID_klienta
GO
/****** Object:  Table [dbo].[Rezerwacje]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rezerwacje](
	[ID_rezerwacji] [int] IDENTITY(1,1) NOT NULL,
	[Data_złożenia] [datetime] NOT NULL,
	[Data_rezerwacji] [datetime] NOT NULL,
	[ID_Restauracji] [int] NOT NULL,
 CONSTRAINT [PK_Rezerwacje] PRIMARY KEY CLUSTERED 
(
	[ID_rezerwacji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Rezerwacje_Firm_Imiennie]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rezerwacje_Firm_Imiennie](
	[ID_rezerwacji] [int] NOT NULL,
	[ID_pracownika] [int] NOT NULL,
	[ID_firmy] [int] NOT NULL,
 CONSTRAINT [PK_Rezerwacje_Firm_Imiennie] PRIMARY KEY CLUSTERED 
(
	[ID_rezerwacji] ASC,
	[ID_pracownika] ASC,
	[ID_firmy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Rezerwacje_Firm]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rezerwacje_Firm](
	[ID_rezerwacji] [int] NOT NULL,
	[ID_firmy] [int] NOT NULL,
 CONSTRAINT [PK_Rezerwacje_Firm] PRIMARY KEY CLUSTERED 
(
	[ID_rezerwacji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Rezerwacje_Ind]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rezerwacje_Ind](
	[ID_rezerwacji] [int] NOT NULL,
	[ID_klienta] [int] NOT NULL,
	[ID_zamówienia] [int] NOT NULL,
 CONSTRAINT [PK_Rezerwacje_Ind] PRIMARY KEY CLUSTERED 
(
	[ID_rezerwacji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Rezerwacje_Na_Dany_Okres]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Rezerwacje_Na_Dany_Okres]
(	
	@id_restauracji int,
	@od date,
	@do date
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT rez.ID_rezerwacji,rez.Data_złożenia,rez.Data_rezerwacji,ki.Imię+' '+ki.Nazwisko AS Nazwa_Klienta FROM Restauracje r
	INNER JOIN Rezerwacje rez ON rez.ID_Restauracji=r.ID_restauracji
	INNER JOIN Rezerwacje_Ind ri ON ri.ID_rezerwacji=rez.ID_rezerwacji
	INNER JOIN Klienci_Ind ki ON ki.ID_klienta=ri.ID_klienta
	WHERE @id_restauracji=r.ID_restauracji AND rez.Data_rezerwacji BETWEEN @od AND @do

	UNION

	SELECT rez.ID_rezerwacji,rez.Data_złożenia,rez.Data_rezerwacji,kb.Nazwa_firmy AS Nazwa_Klienta FROM Restauracje r
	INNER JOIN Rezerwacje rez ON rez.ID_Restauracji=r.ID_restauracji
	INNER JOIN Rezerwacje_Firm rf ON rf.ID_rezerwacji=rez.ID_rezerwacji
	INNER JOIN Klienci_Biz kb ON kb.ID_klienta=rf.ID_firmy
	WHERE @id_restauracji=r.ID_restauracji AND rez.Data_rezerwacji BETWEEN @od AND @do

	UNION

	SELECT DISTINCT rez.ID_rezerwacji,rez.Data_złożenia,rez.Data_rezerwacji,kb.Nazwa_firmy AS Nazwa_Klienta FROM Restauracje r
	INNER JOIN Rezerwacje rez ON rez.ID_Restauracji=r.ID_restauracji
	INNER JOIN Rezerwacje_Firm_Imiennie rfi ON rfi.ID_rezerwacji=rez.ID_rezerwacji
	INNER JOIN Pracownicy_Firm pf ON pf.ID_firmy=rfi.ID_firmy
	INNER JOIN Klienci_Biz kb ON kb.ID_klienta=pf.ID_firmy
	WHERE @id_restauracji=r.ID_restauracji AND rez.Data_rezerwacji BETWEEN @od AND @do
)
GO
/****** Object:  Table [dbo].[Panstwa]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Panstwa](
	[ID_państwa] [int] IDENTITY(1,1) NOT NULL,
	[Nazwa] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Państwa] PRIMARY KEY CLUSTERED 
(
	[ID_państwa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [Un_Państwa_Nazwa] UNIQUE NONCLUSTERED 
(
	[Nazwa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Generuj_Fakture_Zamowienie]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Generuj_Fakture_Zamowienie]
(	
	-- Add the parameters for the function here
	@id_zamowienia int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT CONCAT('Faktura za zamówienie nr: ', ID_zamówienia) AS 'SZCZEGÓŁY', NULL AS 'WARTOŚĆ'
	FROM dbo.Zamówienia
	WHERE ID_zamówienia=@id_zamowienia

	UNION ALL
	SELECT ' ', NULL
	UNION ALL

	SELECT CONCAT('Nazwa firmy: ',kb.Nazwa_firmy), NULL
	FROM dbo.Zamówienia z
	INNER JOIN dbo.Klienci_Biz kb ON kb.ID_klienta=z.ID_klienta
	WHERE ID_zamówienia=@id_zamowienia
	UNION ALL
	SELECT CONCAT('NIP: ',kb.NIP), NULL
	FROM dbo.Zamówienia z
	INNER JOIN dbo.Klienci_Biz kb ON kb.ID_klienta=z.ID_klienta
	WHERE ID_zamówienia=@id_zamowienia
	UNION ALL
	SELECT CONCAT('Adres: ',kb.Ulica, ', ',kb.Kod_pocztowy,', ',m.Nazwa_miasta, ', ',p.Nazwa), NULL
	FROM dbo.Zamówienia z
	INNER JOIN dbo.Klienci_Biz kb ON kb.ID_klienta=z.ID_klienta
	INNER JOIN dbo.Miasta m ON m.ID_miasta=kb.ID_miasta
	INNER JOIN dbo.Panstwa p ON p.ID_państwa = m.ID_państwa
	WHERE ID_zamówienia=@id_zamowienia
	UNION ALL
	SELECT ' ', NULL
	UNION ALL
	SELECT 'Szczegóły zamówienia', NULL
	UNION ALL
	SELECT CONCAT('Zamówione danie:', d.Nazwa_dania, ',   Ilość: ', sz.Ilość, ',   Cena jednostkowa:',
	sz.Cena_jednostkowa
	) AS 'SZCZEGÓŁY', sz.Ilość*sz.Cena_jednostkowa  AS 'SUMA' FROM dbo.Zamówienia z 
	INNER JOIN dbo.Szczegóły_Zamówień sz ON z.ID_zamówienia=sz.ID_zamówienia
	INNER JOIN dbo.Menu m ON m.ID_pozycji=sz.ID_pozycji
	INNER JOIN dbo.Dania d ON d.ID_dania=m.ID_dania
	WHERE z.ID_zamówienia=@id_zamowienia

	UNION ALL

	SELECT 'ŁĄCZNA WARTOŚĆ', dbo.Wartosc_Zamowienia_Z_Rabatem(@id_zamowienia)

)
GO
/****** Object:  Table [dbo].[Obsluga]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Obsluga](
	[ID_pracownika] [int] IDENTITY(1,1) NOT NULL,
	[Imię] [varchar](30) NOT NULL,
	[Nazwisko] [varchar](30) NOT NULL,
	[ID_Restauracji] [int] NOT NULL,
 CONSTRAINT [PK_Obsługa] PRIMARY KEY CLUSTERED 
(
	[ID_pracownika] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Statystyki_Obslugi]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Statystyki_Obslugi]
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT o.ID_pracownika,o.Imię, o.Nazwisko, 
	COUNT(DISTINCT z.ID_zamówienia) AS 'Liczba obsłużonych zamówień',
	SUM(sz.Cena_jednostkowa*sz.Ilość) AS 'Łączna wartość obsłużonych zamówień'
	FROM dbo.Obsluga o 
	INNER JOIN dbo.Zamówienia z ON o.ID_pracownika=z.Pracownik_obsługujący
	INNER JOIN dbo.Szczegóły_Zamówień sz ON sz.ID_zamówienia = z.ID_zamówienia
	WHERE o.ID_Restauracji=@id_restauracji
	GROUP BY o.ID_pracownika,o.Imię,o.Nazwisko
	ORDER BY 5 DESC OFFSET 0 ROWS
	
)
GO
/****** Object:  UserDefinedFunction [dbo].[Statystyki_Zamowien_Klientow_Ind]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Statystyki_Zamowien_Klientow_Ind]
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT ki.Imię,ki.Nazwisko,sum(sz.Cena_jednostkowa*sz.Ilość) as 'Łączna wartość zamówień'
	FROM Klienci_Ind ki
	INNER JOIN Klienci k ON k.ID_klienta=ki.ID_klienta
	INNER JOIN Zamówienia z ON z.ID_klienta=k.ID_klienta
	INNER JOIN Szczegóły_Zamówień sz ON sz.ID_zamówienia=z.ID_zamówienia
	WHERE z.Pracownik_obsługujący IN (SELECT o.ID_pracownika FROM Obsluga o WHERE o.ID_Restauracji=@id_restauracji)
	GROUP BY ki.ID_klienta,ki.Imię,ki.Nazwisko
	ORDER BY 3 DESC OFFSET 0 ROWS
)
GO
/****** Object:  UserDefinedFunction [dbo].[Pracownicy_Firmy]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Pracownicy_Firmy]
(	
	@id_firmy int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT i.Imię,i.Nazwisko
	FROM Klienci_Ind i
	INNER JOIN Pracownicy_Firm f on i.ID_klienta=f.ID_pracownika AND @id_firmy=f.ID_firmy
	INNER JOIN Klienci k on k.ID_klienta=i.ID_klienta
)
GO
/****** Object:  UserDefinedFunction [dbo].[Statystyki_Zamowien_Klientow_Biz]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Statystyki_Zamowien_Klientow_Biz]
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT kb.Nazwa_firmy,sum(sz.Cena_jednostkowa*sz.Ilość) as 'Łączna wartość zamówień'
	FROM Klienci_Biz kb
	INNER JOIN Klienci k ON k.ID_klienta=kb.ID_klienta
	INNER JOIN Zamówienia z ON z.ID_klienta=k.ID_klienta
	INNER JOIN Szczegóły_Zamówień sz ON sz.ID_zamówienia=z.ID_zamówienia
	WHERE z.Pracownik_obsługujący IN (SELECT o.ID_pracownika FROM Obsluga o WHERE o.ID_Restauracji=@id_restauracji)
	GROUP BY kb.ID_klienta,kb.Nazwa_firmy
	ORDER BY 2 DESC OFFSET 0 ROWS
)
GO
/****** Object:  UserDefinedFunction [dbo].[Pokaz_Menu]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Pokaz_Menu]
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT d.Nazwa_dania,m.ID_dania,m.Data_wprowadzenia,d.Cena_dania,d.Opis_dania,m.ID_pozycji FROM Menu m
	INNER JOIN Dania d on m.ID_dania=d.ID_dania
	WHERE ID_restauracji=@id_restauracji AND Data_zdjęcia is NULL
)
GO
/****** Object:  Table [dbo].[Stoliki]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stoliki](
	[ID_stolika] [int] IDENTITY(1,1) NOT NULL,
	[Max_liczba_miejsc] [int] NOT NULL,
	[ID_Restauracji] [int] NOT NULL,
 CONSTRAINT [PK_Stoliki] PRIMARY KEY CLUSTERED 
(
	[ID_stolika] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Szczegóły_Rezerwacji]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Szczegóły_Rezerwacji](
	[ID_rezerwacji] [int] NOT NULL,
	[ID_obostrzenia] [int] NOT NULL,
 CONSTRAINT [PK_Szczegóły_Rezerwacji_1] PRIMARY KEY CLUSTERED 
(
	[ID_rezerwacji] ASC,
	[ID_obostrzenia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Obostrzenia]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Obostrzenia](
	[ID_Obostrzenia] [int] IDENTITY(1,1) NOT NULL,
	[ID_stolika] [int] NOT NULL,
	[Liczba_miejsc] [int] NOT NULL,
	[Data_wprowadzenia] [date] NOT NULL,
 CONSTRAINT [PK_Obostrzenia_1] PRIMARY KEY CLUSTERED 
(
	[ID_Obostrzenia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Statystyki_Rezerwacji_Stolikow]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION  [dbo].[Statystyki_Rezerwacji_Stolikow]
(	
	@id_restauracji int,
	@data_od date,
	@data_do date
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT s.ID_stolika,COUNT(*) as 'liczba rezerwacji' FROM Rezerwacje r
	INNER JOIN Szczegóły_Rezerwacji sr ON sr.ID_rezerwacji=r.ID_rezerwacji
	INNER JOIN Obostrzenia o ON o.ID_Obostrzenia=sr.ID_obostrzenia
	INNER JOIN Stoliki s ON s.ID_stolika=o.ID_stolika
	WHERE r.ID_Restauracji=@id_restauracji AND r.Data_rezerwacji BETWEEN @data_od AND @data_do
	AND s.ID_stolika IN (SELECT ID_stolika FROM dbo.Stoliki WHERE @id_restauracji=ID_Restauracji)
	GROUP BY s.ID_stolika
	ORDER BY 2 DESC OFFSET 0 ROWS
)


GO
/****** Object:  UserDefinedFunction [dbo].[Aktualne_Zamowienia_Klienta]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Aktualne_Zamowienia_Klienta]
(	 
	@id_klienta int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT d.Nazwa_dania,sz.Cena_jednostkowa,sz.Ilość,z.Data_zamówienia,z.Data_odbioru,r.Nazwa
	FROM Zamówienia z
	INNER JOIN Szczegóły_Zamówień sz ON sz.ID_zamówienia=z.ID_zamówienia
	INNER JOIN Menu m ON m.ID_pozycji=sz.ID_pozycji
	INNER JOIN Dania d ON d.ID_dania=m.ID_dania
	INNER JOIN Restauracje r ON r.ID_restauracji=m.ID_restauracji
	WHERE z.Data_odbioru>GETDATE() AND @id_klienta=z.ID_klienta
)
GO
/****** Object:  Table [dbo].[Rabaty]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rabaty](
	[ID_rabatu] [int] IDENTITY(1,1) NOT NULL,
	[Wymagana_kwota] [money] NOT NULL,
	[Wysokosc_jedn] [float] NOT NULL,
	[Data_wprowadzenia] [date] NOT NULL,
	[Data_zdjęcia] [date] NULL,
	[ID_Restauracji] [int] NOT NULL,
 CONSTRAINT [PK_Rabaty] PRIMARY KEY CLUSTERED 
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Aktualnie_Przyznane_Rabaty]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Aktualnie_Przyznane_Rabaty](
	[ID_rabatu] [int] NOT NULL,
	[ID_klienta] [int] NOT NULL,
	[Data_przyznania] [date] NOT NULL,
	[Data_wygaśnięcia] [date] NULL,
 CONSTRAINT [PK_Aktualnie_Przyznane_Rabaty] PRIMARY KEY CLUSTERED 
(
	[ID_rabatu] ASC,
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Aktualne_Rabaty_Klienta]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Aktualne_Rabaty_Klienta]
(	
	@id_klienta int,
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT a.ID_rabatu,a.Data_przyznania,a.Data_wygaśnięcia,ra.Wysokosc_jedn
	FROM Restauracje r
	INNER JOIN Rabaty ra ON r.ID_restauracji=ra.ID_Restauracji
	INNER JOIN Aktualnie_Przyznane_Rabaty a ON a.ID_rabatu=ra.ID_rabatu
	WHERE a.ID_klienta=@id_klienta AND r.ID_restauracji=@id_restauracji
)
GO
/****** Object:  Table [dbo].[Rabaty_Firm_Miesiac]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rabaty_Firm_Miesiac](
	[ID_rabatu] [int] NOT NULL,
	[Liczba_zamowien] [int] NOT NULL,
	[Max_rabat] [float] NOT NULL,
 CONSTRAINT [PK_Rabaty_Firm_Miesiac] PRIMARY KEY CLUSTERED 
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Rabaty_Ind_Stale]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rabaty_Ind_Stale](
	[ID_rabatu] [int] NOT NULL,
	[Liczba_zamowien] [int] NOT NULL,
 CONSTRAINT [PK_Rabaty_Ind_Stale] PRIMARY KEY CLUSTERED 
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Rabaty_Ind_Jednorazowe]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Rabaty_Ind_Jednorazowe](
	[ID_rabatu] [int] NOT NULL,
	[Waznosc] [int] NOT NULL,
 CONSTRAINT [PK_Rabaty_Ind_Jednorazowe] PRIMARY KEY CLUSTERED 
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Raport_Rabatow]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Raport_Rabatow] 
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT CONCAT('Raport rabatow dla restauracji ',@id_restauracji,'.') AS 'SZCZEGOLY',NULL AS 'LICZBA'
	UNION ALL
	SELECT 'Liczba klientow indywidualnych posiadajacych rabat staly:', COUNT(*)
	FROM dbo.Aktualnie_Przyznane_Rabaty apr
	INNER JOIN dbo.Rabaty_Ind_Stale ris ON ris.ID_rabatu=apr.ID_rabatu
	INNER JOIN dbo.Rabaty r 
	ON r.ID_rabatu=ris.ID_rabatu AND r.ID_Restauracji=r.ID_Restauracji AND r.Data_zdjęcia IS NULL
	UNION ALL

	SELECT 'Liczba klientow indywidualnych posiadajacych rabat jednorazowy:', COUNT(*)
	FROM dbo.Aktualnie_Przyznane_Rabaty apr
	INNER JOIN dbo.Rabaty_Ind_Jednorazowe rij ON rij.ID_rabatu=apr.ID_rabatu
	INNER JOIN dbo.Rabaty r 
	ON r.ID_rabatu=rij.ID_rabatu AND r.ID_Restauracji=r.ID_Restauracji AND r.Data_zdjęcia IS NULL

	UNION ALL

		SELECT 'Liczba klientow firmowych posiadajacych rabat miesieczny:', COUNT(*)
	FROM dbo.Aktualnie_Przyznane_Rabaty apr
	INNER JOIN dbo.Rabaty_Firm_Miesiac rfm ON rfm.ID_rabatu=apr.ID_rabatu
	INNER JOIN dbo.Rabaty r 
	ON r.ID_rabatu=rfm.ID_rabatu AND r.ID_Restauracji=r.ID_Restauracji AND r.Data_zdjęcia IS NULL

	UNION ALL

			SELECT 'Liczba klientow firmowych posiadajacych rabat kwartalny:', COUNT(*)
	FROM dbo.Aktualnie_Przyznane_Rabaty apr
	INNER JOIN dbo.Rabaty r ON apr.ID_rabatu=r.ID_rabatu AND r.Data_zdjęcia IS NULL AND r.ID_Restauracji=@id_restauracji
	WHERE apr.ID_rabatu not IN (SELECT id_rabatu FROM dbo.Rabaty_Firm_Miesiac)
	AND apr.ID_rabatu NOT IN (SELECT id_rabatu FROM dbo.Rabaty_Ind_Jednorazowe)
	AND apr.ID_rabatu NOT IN (SELECT id_rabatu FROM dbo.Rabaty_Ind_Stale)
)
GO
/****** Object:  UserDefinedFunction [dbo].[Statystyki_Rezerwacji_Stolikow_Miesiac]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Statystyki_Rezerwacji_Stolikow_Miesiac] 
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM dbo.Statystyki_Rezerwacji_Stolikow(@id_restauracji, DATEADD(DAY,-30,GETDATE()),GETDATE())
)
GO
/****** Object:  UserDefinedFunction [dbo].[Dania_Z_Kategorii]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Dania_Z_Kategorii] 
(	
	@id_kategorii int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT Nazwa_dania,Cena_dania FROM Dania
	WHERE Kategoria=@id_kategorii
)
GO
/****** Object:  UserDefinedFunction [dbo].[Statystyki_Rezerwacji_Stolikow_Tydzien]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Statystyki_Rezerwacji_Stolikow_Tydzien] 
(	
	@id_restauracji int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT * FROM dbo.Statystyki_Rezerwacji_Stolikow(@id_restauracji, DATEADD(DAY,-7,GETDATE()),GETDATE())

)
GO
/****** Object:  Table [dbo].[Szczegóły_Dostaw]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Szczegóły_Dostaw](
	[ID_dostawy] [int] NOT NULL,
	[ID_półproduktu] [int] NOT NULL,
	[Ilość_jednostek] [float] NOT NULL,
 CONSTRAINT [PK_Szczegóły_Dostaw] PRIMARY KEY CLUSTERED 
(
	[ID_dostawy] ASC,
	[ID_półproduktu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Dostawcy]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dostawcy](
	[ID_dostawcy] [int] IDENTITY(1,1) NOT NULL,
	[Nazwa_firmy] [varchar](50) NOT NULL,
	[Ulica] [varchar](50) NOT NULL,
	[Kod_pocztowy] [varchar](6) NOT NULL,
	[ID_miasta] [int] NOT NULL,
	[Telefon_kontaktowy] [varchar](9) NOT NULL,
 CONSTRAINT [PK_Dostawcy] PRIMARY KEY CLUSTERED 
(
	[ID_dostawcy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Dostawy]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dostawy](
	[ID_dostawy] [int] IDENTITY(1,1) NOT NULL,
	[ID_dostawcy] [int] NOT NULL,
	[Data_zamówienia] [date] NOT NULL,
	[Data_dostawy] [date] NULL,
	[ID_Restauracji] [int] NOT NULL,
 CONSTRAINT [PK_Dostawy] PRIMARY KEY CLUSTERED 
(
	[ID_dostawy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Dostawy_Niezrealizowane]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Dostawy_Niezrealizowane]
(	
	@id_lokalu int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT d.ID_dostawy,p.Nazwa,sd.Ilość_jednostek,d.Data_zamówienia,do.Nazwa_firmy,do.Telefon_kontaktowy FROM Dostawy d
	INNER JOIN Dostawcy do ON do.ID_dostawcy=d.ID_dostawcy
	INNER JOIN Szczegóły_Dostaw sd ON sd.ID_dostawy=d.ID_dostawy
	INNER JOIN Półprodukty p ON p.ID_półproduktu=sd.ID_półproduktu
	WHERE d.ID_Restauracji=@id_lokalu AND d.Data_dostawy is NULL
)
GO
/****** Object:  Table [dbo].[Kategorie]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Kategorie](
	[ID_kategorii] [int] IDENTITY(1,1) NOT NULL,
	[Nazwa_kategorii] [varchar](30) NOT NULL,
 CONSTRAINT [PK_Kategorie] PRIMARY KEY CLUSTERED 
(
	[ID_kategorii] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [Nazwa_Kategorie] UNIQUE NONCLUSTERED 
(
	[Nazwa_kategorii] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Pokaz_Menu_Dnia]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Pokaz_Menu_Dnia]
(	
 @id_restauracji INT,
 @data date
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT ID_pozycji,Data_wprowadzenia,Data_zdjęcia,Menu.ID_dania, Nazwa_dania,Cena_dania, Opis_dania FROM dbo.Menu
	INNER JOIN dbo.Dania ON dbo.Menu.ID_dania=dbo.Dania.ID_dania
	INNER JOIN dbo.Kategorie ON Dania.Kategoria = dbo.Kategorie.ID_kategorii
	WHERE ID_restauracji=@id_restauracji 
	AND (
	(Data_zdjęcia IS NULL AND Data_wprowadzenia<=@data)
	OR 
	(Data_zdjęcia  IS NOT NULL and @data BETWEEN Data_wprowadzenia AND Data_zdjęcia)
	)
)
GO
/****** Object:  Table [dbo].[Aktualnie_Dostarcza]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Aktualnie_Dostarcza](
	[ID_dostawcy] [int] NOT NULL,
	[ID_produktu] [int] NOT NULL,
 CONSTRAINT [PK_Aktualnie_Dostarcza] PRIMARY KEY CLUSTERED 
(
	[ID_dostawcy] ASC,
	[ID_produktu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  UserDefinedFunction [dbo].[Znajdz_Dostawce_Polproduktu]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Znajdz_Dostawce_Polproduktu]
(	
	@id_polproduktu int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT d.Nazwa_firmy,d.Telefon_kontaktowy FROM Aktualnie_Dostarcza a
	INNER JOIN Dostawcy d on d.ID_dostawcy=a.ID_dostawcy
	WHERE a.ID_produktu=@id_polproduktu
)
GO
/****** Object:  UserDefinedFunction [dbo].[Mozliwe_Dania_Do_Wstawienia]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Mozliwe_Dania_Do_Wstawienia]
(	
	@id_restauracji INT,
    @data date
)
RETURNS TABLE 
AS
RETURN 
(
	(SELECT DISTINCT d.ID_dania,d.Nazwa_dania FROM Dania d  LEFT OUTER JOIN Menu m ON m.ID_dania=d.ID_dania 
	AND m.ID_restauracji=@id_restauracji
	WHERE m.Data_wprowadzenia IS NULL OR m.Data_zdjęcia<=DATEADD(DAY,-30,@data) AND d.ID_Dania NOT IN (SELECT m2.ID_dania FROM Menu m2 
										WHERE m2.Data_wprowadzenia>DATEADD(DAY,-30,@data) AND m2.ID_restauracji=@id_restauracji))
)
GO
/****** Object:  UserDefinedFunction [dbo].[Rezerwacje_Klienta_Biz]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Rezerwacje_Klienta_Biz] 
(	
	@id_firmy int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT r.ID_rezerwacji,r.Data_rezerwacji,re.Nazwa,o.ID_stolika
	FROM Rezerwacje_Firm fr
	INNER JOIN Rezerwacje r ON r.ID_rezerwacji=fr.ID_rezerwacji
	INNER JOIN Szczegóły_Rezerwacji sr ON r.ID_rezerwacji=sr.ID_rezerwacji
	INNER JOIN Obostrzenia o ON o.ID_Obostrzenia=sr.ID_obostrzenia
	INNER JOIN Restauracje re ON re.ID_restauracji=r.ID_Restauracji
	WHERE @id_firmy=fr.ID_firmy AND r.Data_rezerwacji>GETDATE()
)
GO
/****** Object:  View [dbo].[V_Owoce_Morza]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Owoce_Morza]
AS
SELECT        dbo.Dania.Nazwa_dania, dbo.Dania.Cena_dania
FROM            dbo.Dania INNER JOIN
                         dbo.Kategorie ON dbo.Dania.Kategoria = dbo.Kategorie.ID_kategorii
WHERE        (dbo.Kategorie.Nazwa_kategorii = 'seafood')
GO
/****** Object:  UserDefinedFunction [dbo].[Rezerwacje_Klienta_Ind]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Rezerwacje_Klienta_Ind]
(	
	@id_klienta int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT r.Data_złożenia,r.Data_rezerwacji,re.Nazwa,o.ID_stolika,o.Liczba_miejsc,ri.ID_zamówienia
	FROM Rezerwacje r
	INNER JOIN Restauracje re ON r.ID_Restauracji=re.ID_restauracji
	INNER JOIN Rezerwacje_Ind ri ON ri.ID_rezerwacji=r.ID_rezerwacji
	INNER JOIN Szczegóły_Rezerwacji sr ON sr.ID_rezerwacji=r.ID_rezerwacji
	INNER JOIN Obostrzenia o ON o.ID_Obostrzenia=sr.ID_obostrzenia
	WHERE ri.ID_klienta=@id_klienta AND r.Data_rezerwacji>GETDATE()
)
GO
/****** Object:  UserDefinedFunction [dbo].[Lista_Rezerwacja_Imiennie]    Script Date: 2021-01-20 23:12:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[Lista_Rezerwacja_Imiennie]
(	
	@id_firmy int
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT k.Imię,k.Nazwisko,r.ID_rezerwacji,r.Data_rezerwacji,re.Nazwa,o.ID_stolika
	FROM Rezerwacje_Firm_Imiennie rfi
	INNER JOIN Rezerwacje r ON r.ID_rezerwacji=rfi.ID_rezerwacji
	INNER JOIN Restauracje re ON re.ID_restauracji=r.ID_Restauracji
	INNER JOIN Pracownicy_Firm pf ON pf.ID_firmy=rfi.ID_firmy AND pf.ID_pracownika=rfi.ID_pracownika
	INNER JOIN Klienci_Ind k ON k.ID_klienta=pf.ID_pracownika
	INNER JOIN Szczegóły_Rezerwacji sr ON sr.ID_rezerwacji=r.ID_rezerwacji
	INNER JOIN Obostrzenia o ON o.ID_Obostrzenia=sr.ID_obostrzenia
	WHERE @id_firmy=rfi.ID_firmy AND r.Data_rezerwacji>GETDATE()
)
GO
/****** Object:  Index [IX_Aktualnie_Dostarcza]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Aktualnie_Dostarcza] ON [dbo].[Aktualnie_Dostarcza]
(
	[ID_dostawcy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Aktualnie_Dostarcza_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Aktualnie_Dostarcza_1] ON [dbo].[Aktualnie_Dostarcza]
(
	[ID_produktu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Aktualnie_Przyznane_Rabaty]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Aktualnie_Przyznane_Rabaty] ON [dbo].[Aktualnie_Przyznane_Rabaty]
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Aktualnie_Przyznane_Rabaty_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Aktualnie_Przyznane_Rabaty_1] ON [dbo].[Aktualnie_Przyznane_Rabaty]
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Dostawy]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Dostawy] ON [dbo].[Dostawy]
(
	[ID_dostawcy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Dostawy_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Dostawy_1] ON [dbo].[Dostawy]
(
	[ID_Restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Klienci_Biz]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Klienci_Biz] ON [dbo].[Klienci_Biz]
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Klienci_Biz_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Klienci_Biz_1] ON [dbo].[Klienci_Biz]
(
	[ID_miasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Klienci_Ind]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Klienci_Ind] ON [dbo].[Klienci_Ind]
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Menu]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Menu] ON [dbo].[Menu]
(
	[ID_dania] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Menu_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Menu_1] ON [dbo].[Menu]
(
	[ID_restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Miasta]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Miasta] ON [dbo].[Miasta]
(
	[Nazwa_miasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Miasta_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Miasta_1] ON [dbo].[Miasta]
(
	[ID_państwa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Obostrzenia]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Obostrzenia] ON [dbo].[Obostrzenia]
(
	[ID_stolika] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Obsluga]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Obsluga] ON [dbo].[Obsluga]
(
	[ID_Restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Panstwa]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Panstwa] ON [dbo].[Panstwa]
(
	[ID_państwa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Panstwa_2]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Panstwa_2] ON [dbo].[Panstwa]
(
	[Nazwa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Polprodukty]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Polprodukty] ON [dbo].[Polprodukty]
(
	[Nazwa] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Pracownicy_Firm]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Pracownicy_Firm] ON [dbo].[Pracownicy_Firm]
(
	[ID_firmy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Pracownicy_Firm_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Pracownicy_Firm_1] ON [dbo].[Pracownicy_Firm]
(
	[ID_pracownika] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Przepisy]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Przepisy] ON [dbo].[Przepisy]
(
	[ID_półproduktu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rabaty]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rabaty] ON [dbo].[Rabaty]
(
	[ID_Restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rabaty_Firm_Miesiac]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rabaty_Firm_Miesiac] ON [dbo].[Rabaty_Firm_Miesiac]
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rabaty_Ind_Jednorazowe]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rabaty_Ind_Jednorazowe] ON [dbo].[Rabaty_Ind_Jednorazowe]
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rabaty_Ind_Stale]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rabaty_Ind_Stale] ON [dbo].[Rabaty_Ind_Stale]
(
	[ID_rabatu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje] ON [dbo].[Rezerwacje]
(
	[ID_Restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Firm]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Firm] ON [dbo].[Rezerwacje_Firm]
(
	[ID_rezerwacji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Firm_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Firm_1] ON [dbo].[Rezerwacje_Firm]
(
	[ID_firmy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Firm_Imiennie]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Firm_Imiennie] ON [dbo].[Rezerwacje_Firm_Imiennie]
(
	[ID_rezerwacji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Firm_Imiennie_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Firm_Imiennie_1] ON [dbo].[Rezerwacje_Firm_Imiennie]
(
	[ID_pracownika] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Firm_Imiennie_2]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Firm_Imiennie_2] ON [dbo].[Rezerwacje_Firm_Imiennie]
(
	[ID_firmy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Ind]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Ind] ON [dbo].[Rezerwacje_Ind]
(
	[ID_rezerwacji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Ind_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Ind_1] ON [dbo].[Rezerwacje_Ind]
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Rezerwacje_Ind_2]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Rezerwacje_Ind_2] ON [dbo].[Rezerwacje_Ind]
(
	[ID_zamówienia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Stan_Magazynowy]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Stan_Magazynowy] ON [dbo].[Stan_Magazynowy]
(
	[ID_restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Stoliki]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Stoliki] ON [dbo].[Stoliki]
(
	[ID_Restauracji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Szczegoly_Dostaw]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Szczegoly_Dostaw] ON [dbo].[Szczegóły_Dostaw]
(
	[ID_dostawy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Szczegoly_Dostaw_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Szczegoly_Dostaw_1] ON [dbo].[Szczegóły_Dostaw]
(
	[ID_półproduktu] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Szczegoly_Rezerwacji]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Szczegoly_Rezerwacji] ON [dbo].[Szczegóły_Rezerwacji]
(
	[ID_rezerwacji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Szczegoly_Rezerwacji_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Szczegoly_Rezerwacji_1] ON [dbo].[Szczegóły_Rezerwacji]
(
	[ID_obostrzenia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Szczegoly_Zamowien]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Szczegoly_Zamowien] ON [dbo].[Szczegóły_Zamówień]
(
	[ID_zamówienia] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Szczegoly_Zamowien_1]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Szczegoly_Zamowien_1] ON [dbo].[Szczegóły_Zamówień]
(
	[ID_pozycji] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Zamowienia]    Script Date: 2021-01-20 23:12:02 ******/
CREATE NONCLUSTERED INDEX [IX_Zamowienia] ON [dbo].[Zamówienia]
(
	[ID_klienta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Aktualnie_Przyznane_Rabaty] ADD  CONSTRAINT [DF_Aktualnie_Przyznane_Rabaty_Data_przyznania]  DEFAULT (getdate()) FOR [Data_przyznania]
GO
ALTER TABLE [dbo].[Dostawy] ADD  CONSTRAINT [DF_Dostawy_Data_zamówienia]  DEFAULT (getdate()) FOR [Data_zamówienia]
GO
ALTER TABLE [dbo].[Menu] ADD  CONSTRAINT [DF_Menu_Data_wprowadzenia]  DEFAULT (getdate()) FOR [Data_wprowadzenia]
GO
ALTER TABLE [dbo].[Obostrzenia] ADD  CONSTRAINT [DF_Obostrzenia_Data_wprowadzenia]  DEFAULT (getdate()) FOR [Data_wprowadzenia]
GO
ALTER TABLE [dbo].[Rabaty] ADD  CONSTRAINT [DF_Rabaty_Data_wprowadzenia]  DEFAULT (getdate()) FOR [Data_wprowadzenia]
GO
ALTER TABLE [dbo].[Rezerwacje] ADD  CONSTRAINT [DF_Rezerwacje_Data_złożenia]  DEFAULT (getdate()) FOR [Data_złożenia]
GO
ALTER TABLE [dbo].[Zamówienia] ADD  CONSTRAINT [DF_Zamówienia_Data_zamówienia]  DEFAULT (getdate()) FOR [Data_zamówienia]
GO
ALTER TABLE [dbo].[Aktualnie_Dostarcza]  WITH CHECK ADD  CONSTRAINT [FK_Aktualnie_Dostarcza_Dostawcy] FOREIGN KEY([ID_dostawcy])
REFERENCES [dbo].[Dostawcy] ([ID_dostawcy])
GO
ALTER TABLE [dbo].[Aktualnie_Dostarcza] CHECK CONSTRAINT [FK_Aktualnie_Dostarcza_Dostawcy]
GO
ALTER TABLE [dbo].[Aktualnie_Dostarcza]  WITH CHECK ADD  CONSTRAINT [FK_Aktualnie_Dostarcza_Półprodukty] FOREIGN KEY([ID_produktu])
REFERENCES [dbo].[Polprodukty] ([ID_półproduktu])
GO
ALTER TABLE [dbo].[Aktualnie_Dostarcza] CHECK CONSTRAINT [FK_Aktualnie_Dostarcza_Półprodukty]
GO
ALTER TABLE [dbo].[Aktualnie_Przyznane_Rabaty]  WITH CHECK ADD  CONSTRAINT [FK_Aktualnie_Przyznane_Rabaty_Klienci] FOREIGN KEY([ID_klienta])
REFERENCES [dbo].[Klienci] ([ID_klienta])
GO
ALTER TABLE [dbo].[Aktualnie_Przyznane_Rabaty] CHECK CONSTRAINT [FK_Aktualnie_Przyznane_Rabaty_Klienci]
GO
ALTER TABLE [dbo].[Aktualnie_Przyznane_Rabaty]  WITH CHECK ADD  CONSTRAINT [FK_Aktualnie_Przyznane_Rabaty_Rabaty1] FOREIGN KEY([ID_rabatu])
REFERENCES [dbo].[Rabaty] ([ID_rabatu])
GO
ALTER TABLE [dbo].[Aktualnie_Przyznane_Rabaty] CHECK CONSTRAINT [FK_Aktualnie_Przyznane_Rabaty_Rabaty1]
GO
ALTER TABLE [dbo].[Dania]  WITH CHECK ADD  CONSTRAINT [FK_Dania_Kategorie] FOREIGN KEY([Kategoria])
REFERENCES [dbo].[Kategorie] ([ID_kategorii])
GO
ALTER TABLE [dbo].[Dania] CHECK CONSTRAINT [FK_Dania_Kategorie]
GO
ALTER TABLE [dbo].[Dostawcy]  WITH CHECK ADD  CONSTRAINT [FK_Dostawcy_Miasta] FOREIGN KEY([ID_miasta])
REFERENCES [dbo].[Miasta] ([ID_miasta])
GO
ALTER TABLE [dbo].[Dostawcy] CHECK CONSTRAINT [FK_Dostawcy_Miasta]
GO
ALTER TABLE [dbo].[Dostawy]  WITH CHECK ADD  CONSTRAINT [FK_Dostawy_Dostawcy] FOREIGN KEY([ID_dostawcy])
REFERENCES [dbo].[Dostawcy] ([ID_dostawcy])
GO
ALTER TABLE [dbo].[Dostawy] CHECK CONSTRAINT [FK_Dostawy_Dostawcy]
GO
ALTER TABLE [dbo].[Dostawy]  WITH CHECK ADD  CONSTRAINT [FK_Dostawy_Restauracje] FOREIGN KEY([ID_Restauracji])
REFERENCES [dbo].[Restauracje] ([ID_restauracji])
GO
ALTER TABLE [dbo].[Dostawy] CHECK CONSTRAINT [FK_Dostawy_Restauracje]
GO
ALTER TABLE [dbo].[Klienci_Biz]  WITH CHECK ADD  CONSTRAINT [FK_Klienci_Biz_Klienci] FOREIGN KEY([ID_klienta])
REFERENCES [dbo].[Klienci] ([ID_klienta])
GO
ALTER TABLE [dbo].[Klienci_Biz] CHECK CONSTRAINT [FK_Klienci_Biz_Klienci]
GO
ALTER TABLE [dbo].[Klienci_Biz]  WITH CHECK ADD  CONSTRAINT [FK_Klienci_Biz_Miasta] FOREIGN KEY([ID_miasta])
REFERENCES [dbo].[Miasta] ([ID_miasta])
GO
ALTER TABLE [dbo].[Klienci_Biz] CHECK CONSTRAINT [FK_Klienci_Biz_Miasta]
GO
ALTER TABLE [dbo].[Klienci_Ind]  WITH CHECK ADD  CONSTRAINT [FK_Klienci_Ind_Klienci1] FOREIGN KEY([ID_klienta])
REFERENCES [dbo].[Klienci] ([ID_klienta])
GO
ALTER TABLE [dbo].[Klienci_Ind] CHECK CONSTRAINT [FK_Klienci_Ind_Klienci1]
GO
ALTER TABLE [dbo].[Menu]  WITH CHECK ADD  CONSTRAINT [FK_Menu_Dania1] FOREIGN KEY([ID_dania])
REFERENCES [dbo].[Dania] ([ID_dania])
GO
ALTER TABLE [dbo].[Menu] CHECK CONSTRAINT [FK_Menu_Dania1]
GO
ALTER TABLE [dbo].[Menu]  WITH CHECK ADD  CONSTRAINT [FK_Menu_Restauracje] FOREIGN KEY([ID_restauracji])
REFERENCES [dbo].[Restauracje] ([ID_restauracji])
GO
ALTER TABLE [dbo].[Menu] CHECK CONSTRAINT [FK_Menu_Restauracje]
GO
ALTER TABLE [dbo].[Miasta]  WITH CHECK ADD  CONSTRAINT [FK_Miasta_Państwa] FOREIGN KEY([ID_państwa])
REFERENCES [dbo].[Panstwa] ([ID_państwa])
GO
ALTER TABLE [dbo].[Miasta] CHECK CONSTRAINT [FK_Miasta_Państwa]
GO
ALTER TABLE [dbo].[Obostrzenia]  WITH CHECK ADD  CONSTRAINT [FK_Obostrzenia_Stoliki] FOREIGN KEY([ID_stolika])
REFERENCES [dbo].[Stoliki] ([ID_stolika])
GO
ALTER TABLE [dbo].[Obostrzenia] CHECK CONSTRAINT [FK_Obostrzenia_Stoliki]
GO
ALTER TABLE [dbo].[Obsluga]  WITH CHECK ADD  CONSTRAINT [FK_Obsługa_Restauracje] FOREIGN KEY([ID_Restauracji])
REFERENCES [dbo].[Restauracje] ([ID_restauracji])
GO
ALTER TABLE [dbo].[Obsluga] CHECK CONSTRAINT [FK_Obsługa_Restauracje]
GO
ALTER TABLE [dbo].[Pracownicy_Firm]  WITH CHECK ADD  CONSTRAINT [FK_Pracownicy_Firm_Klienci_Biz] FOREIGN KEY([ID_firmy])
REFERENCES [dbo].[Klienci_Biz] ([ID_klienta])
GO
ALTER TABLE [dbo].[Pracownicy_Firm] CHECK CONSTRAINT [FK_Pracownicy_Firm_Klienci_Biz]
GO
ALTER TABLE [dbo].[Pracownicy_Firm]  WITH CHECK ADD  CONSTRAINT [FK_Pracownicy_Firm_Klienci_Ind] FOREIGN KEY([ID_pracownika])
REFERENCES [dbo].[Klienci_Ind] ([ID_klienta])
GO
ALTER TABLE [dbo].[Pracownicy_Firm] CHECK CONSTRAINT [FK_Pracownicy_Firm_Klienci_Ind]
GO
ALTER TABLE [dbo].[Przepisy]  WITH CHECK ADD  CONSTRAINT [FK_Przepisy_Dania] FOREIGN KEY([ID_dania])
REFERENCES [dbo].[Dania] ([ID_dania])
GO
ALTER TABLE [dbo].[Przepisy] CHECK CONSTRAINT [FK_Przepisy_Dania]
GO
ALTER TABLE [dbo].[Przepisy]  WITH CHECK ADD  CONSTRAINT [FK_Przepisy_Półprodukty] FOREIGN KEY([ID_półproduktu])
REFERENCES [dbo].[Polprodukty] ([ID_półproduktu])
GO
ALTER TABLE [dbo].[Przepisy] CHECK CONSTRAINT [FK_Przepisy_Półprodukty]
GO
ALTER TABLE [dbo].[Rabaty]  WITH CHECK ADD  CONSTRAINT [FK_Rabaty_Restauracje] FOREIGN KEY([ID_Restauracji])
REFERENCES [dbo].[Restauracje] ([ID_restauracji])
GO
ALTER TABLE [dbo].[Rabaty] CHECK CONSTRAINT [FK_Rabaty_Restauracje]
GO
ALTER TABLE [dbo].[Rabaty_Firm_Miesiac]  WITH CHECK ADD  CONSTRAINT [FK_Rabaty_Firm_Miesiac_Rabaty] FOREIGN KEY([ID_rabatu])
REFERENCES [dbo].[Rabaty] ([ID_rabatu])
GO
ALTER TABLE [dbo].[Rabaty_Firm_Miesiac] CHECK CONSTRAINT [FK_Rabaty_Firm_Miesiac_Rabaty]
GO
ALTER TABLE [dbo].[Rabaty_Ind_Jednorazowe]  WITH CHECK ADD  CONSTRAINT [FK_Rabaty_Ind_Jednorazowe_Rabaty] FOREIGN KEY([ID_rabatu])
REFERENCES [dbo].[Rabaty] ([ID_rabatu])
GO
ALTER TABLE [dbo].[Rabaty_Ind_Jednorazowe] CHECK CONSTRAINT [FK_Rabaty_Ind_Jednorazowe_Rabaty]
GO
ALTER TABLE [dbo].[Rabaty_Ind_Stale]  WITH CHECK ADD  CONSTRAINT [FK_Rabaty_Ind_Stale_Rabaty1] FOREIGN KEY([ID_rabatu])
REFERENCES [dbo].[Rabaty] ([ID_rabatu])
GO
ALTER TABLE [dbo].[Rabaty_Ind_Stale] CHECK CONSTRAINT [FK_Rabaty_Ind_Stale_Rabaty1]
GO
ALTER TABLE [dbo].[Restauracje]  WITH CHECK ADD  CONSTRAINT [FK_Restauracje_Miasta] FOREIGN KEY([Miasto])
REFERENCES [dbo].[Miasta] ([ID_miasta])
GO
ALTER TABLE [dbo].[Restauracje] CHECK CONSTRAINT [FK_Restauracje_Miasta]
GO
ALTER TABLE [dbo].[Rezerwacje]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Restauracje] FOREIGN KEY([ID_Restauracji])
REFERENCES [dbo].[Restauracje] ([ID_restauracji])
GO
ALTER TABLE [dbo].[Rezerwacje] CHECK CONSTRAINT [FK_Rezerwacje_Restauracje]
GO
ALTER TABLE [dbo].[Rezerwacje_Firm]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Firm_Klienci_Biz] FOREIGN KEY([ID_firmy])
REFERENCES [dbo].[Klienci_Biz] ([ID_klienta])
GO
ALTER TABLE [dbo].[Rezerwacje_Firm] CHECK CONSTRAINT [FK_Rezerwacje_Firm_Klienci_Biz]
GO
ALTER TABLE [dbo].[Rezerwacje_Firm]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Firm_Rezerwacje] FOREIGN KEY([ID_rezerwacji])
REFERENCES [dbo].[Rezerwacje] ([ID_rezerwacji])
GO
ALTER TABLE [dbo].[Rezerwacje_Firm] CHECK CONSTRAINT [FK_Rezerwacje_Firm_Rezerwacje]
GO
ALTER TABLE [dbo].[Rezerwacje_Firm_Imiennie]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Firm_Imiennie_Pracownicy_Firm] FOREIGN KEY([ID_firmy], [ID_pracownika])
REFERENCES [dbo].[Pracownicy_Firm] ([ID_firmy], [ID_pracownika])
GO
ALTER TABLE [dbo].[Rezerwacje_Firm_Imiennie] CHECK CONSTRAINT [FK_Rezerwacje_Firm_Imiennie_Pracownicy_Firm]
GO
ALTER TABLE [dbo].[Rezerwacje_Firm_Imiennie]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Firm_Imiennie_Rezerwacje] FOREIGN KEY([ID_rezerwacji])
REFERENCES [dbo].[Rezerwacje] ([ID_rezerwacji])
GO
ALTER TABLE [dbo].[Rezerwacje_Firm_Imiennie] CHECK CONSTRAINT [FK_Rezerwacje_Firm_Imiennie_Rezerwacje]
GO
ALTER TABLE [dbo].[Rezerwacje_Ind]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Ind_Klienci_Ind] FOREIGN KEY([ID_klienta])
REFERENCES [dbo].[Klienci_Ind] ([ID_klienta])
GO
ALTER TABLE [dbo].[Rezerwacje_Ind] CHECK CONSTRAINT [FK_Rezerwacje_Ind_Klienci_Ind]
GO
ALTER TABLE [dbo].[Rezerwacje_Ind]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Ind_Rezerwacje] FOREIGN KEY([ID_rezerwacji])
REFERENCES [dbo].[Rezerwacje] ([ID_rezerwacji])
GO
ALTER TABLE [dbo].[Rezerwacje_Ind] CHECK CONSTRAINT [FK_Rezerwacje_Ind_Rezerwacje]
GO
ALTER TABLE [dbo].[Rezerwacje_Ind]  WITH CHECK ADD  CONSTRAINT [FK_Rezerwacje_Ind_Zamówienia] FOREIGN KEY([ID_zamówienia])
REFERENCES [dbo].[Zamówienia] ([ID_zamówienia])
GO
ALTER TABLE [dbo].[Rezerwacje_Ind] CHECK CONSTRAINT [FK_Rezerwacje_Ind_Zamówienia]
GO
ALTER TABLE [dbo].[Stan_Magazynowy]  WITH CHECK ADD  CONSTRAINT [FK_StanMagazynowy_Półprodukty] FOREIGN KEY([ID_półproduktu])
REFERENCES [dbo].[Polprodukty] ([ID_półproduktu])
GO
ALTER TABLE [dbo].[Stan_Magazynowy] CHECK CONSTRAINT [FK_StanMagazynowy_Półprodukty]
GO
ALTER TABLE [dbo].[Stan_Magazynowy]  WITH CHECK ADD  CONSTRAINT [FK_StanMagazynowy_Restauracje] FOREIGN KEY([ID_restauracji])
REFERENCES [dbo].[Restauracje] ([ID_restauracji])
GO
ALTER TABLE [dbo].[Stan_Magazynowy] CHECK CONSTRAINT [FK_StanMagazynowy_Restauracje]
GO
ALTER TABLE [dbo].[Stoliki]  WITH CHECK ADD  CONSTRAINT [FK_Stoliki_Restauracje] FOREIGN KEY([ID_Restauracji])
REFERENCES [dbo].[Restauracje] ([ID_restauracji])
GO
ALTER TABLE [dbo].[Stoliki] CHECK CONSTRAINT [FK_Stoliki_Restauracje]
GO
ALTER TABLE [dbo].[Szczegóły_Dostaw]  WITH CHECK ADD  CONSTRAINT [FK_Szczegóły_Dostaw_Dostawy] FOREIGN KEY([ID_dostawy])
REFERENCES [dbo].[Dostawy] ([ID_dostawy])
GO
ALTER TABLE [dbo].[Szczegóły_Dostaw] CHECK CONSTRAINT [FK_Szczegóły_Dostaw_Dostawy]
GO
ALTER TABLE [dbo].[Szczegóły_Dostaw]  WITH CHECK ADD  CONSTRAINT [FK_Szczegóły_Dostaw_Półprodukty] FOREIGN KEY([ID_półproduktu])
REFERENCES [dbo].[Polprodukty] ([ID_półproduktu])
GO
ALTER TABLE [dbo].[Szczegóły_Dostaw] CHECK CONSTRAINT [FK_Szczegóły_Dostaw_Półprodukty]
GO
ALTER TABLE [dbo].[Szczegóły_Rezerwacji]  WITH CHECK ADD  CONSTRAINT [FK_Szczegóły_Rezerwacji_Obostrzenia] FOREIGN KEY([ID_obostrzenia])
REFERENCES [dbo].[Obostrzenia] ([ID_Obostrzenia])
GO
ALTER TABLE [dbo].[Szczegóły_Rezerwacji] CHECK CONSTRAINT [FK_Szczegóły_Rezerwacji_Obostrzenia]
GO
ALTER TABLE [dbo].[Szczegóły_Rezerwacji]  WITH CHECK ADD  CONSTRAINT [FK_Szczegóły_Rezerwacji_Rezerwacje] FOREIGN KEY([ID_rezerwacji])
REFERENCES [dbo].[Rezerwacje] ([ID_rezerwacji])
GO
ALTER TABLE [dbo].[Szczegóły_Rezerwacji] CHECK CONSTRAINT [FK_Szczegóły_Rezerwacji_Rezerwacje]
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień]  WITH CHECK ADD  CONSTRAINT [FK_Szczegóły_Zamówień_Menu] FOREIGN KEY([ID_pozycji])
REFERENCES [dbo].[Menu] ([ID_pozycji])
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień] CHECK CONSTRAINT [FK_Szczegóły_Zamówień_Menu]
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień]  WITH CHECK ADD  CONSTRAINT [FK_Szczegóły_Zamówień_Zamówienia] FOREIGN KEY([ID_zamówienia])
REFERENCES [dbo].[Zamówienia] ([ID_zamówienia])
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień] CHECK CONSTRAINT [FK_Szczegóły_Zamówień_Zamówienia]
GO
ALTER TABLE [dbo].[Zamówienia]  WITH CHECK ADD  CONSTRAINT [FK_Zamówienia_Klienci] FOREIGN KEY([ID_klienta])
REFERENCES [dbo].[Klienci] ([ID_klienta])
GO
ALTER TABLE [dbo].[Zamówienia] CHECK CONSTRAINT [FK_Zamówienia_Klienci]
GO
ALTER TABLE [dbo].[Zamówienia]  WITH CHECK ADD  CONSTRAINT [FK_Zamówienia_Obsługa] FOREIGN KEY([Pracownik_obsługujący])
REFERENCES [dbo].[Obsluga] ([ID_pracownika])
GO
ALTER TABLE [dbo].[Zamówienia] CHECK CONSTRAINT [FK_Zamówienia_Obsługa]
GO
ALTER TABLE [dbo].[Aktualnie_Przyznane_Rabaty]  WITH CHECK ADD  CONSTRAINT [CK_Aktualnie_Przyznane_Rabaty_Daty] CHECK  (([Data_przyznania]<=getdate() AND ([Data_wygaśnięcia] IS NULL OR [Data_wygaśnięcia]>=[Data_przyznania])))
GO
ALTER TABLE [dbo].[Aktualnie_Przyznane_Rabaty] CHECK CONSTRAINT [CK_Aktualnie_Przyznane_Rabaty_Daty]
GO
ALTER TABLE [dbo].[Dania]  WITH CHECK ADD  CONSTRAINT [CK_Dania_Cena] CHECK  (([Cena_dania]>(0)))
GO
ALTER TABLE [dbo].[Dania] CHECK CONSTRAINT [CK_Dania_Cena]
GO
ALTER TABLE [dbo].[Dania]  WITH CHECK ADD  CONSTRAINT [CK_Dania_Nazwa_Dania_Min] CHECK  ((len([Nazwa_dania])>(2)))
GO
ALTER TABLE [dbo].[Dania] CHECK CONSTRAINT [CK_Dania_Nazwa_Dania_Min]
GO
ALTER TABLE [dbo].[Dostawcy]  WITH CHECK ADD  CONSTRAINT [CK_Dostawcy_Kod_pocztowy] CHECK  (([Kod_pocztowy] like '[0-9][0-9][0-9][0-9][0-9]' OR [Kod_pocztowy] like '[0-9][0-9]-[0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Dostawcy] CHECK CONSTRAINT [CK_Dostawcy_Kod_pocztowy]
GO
ALTER TABLE [dbo].[Dostawcy]  WITH CHECK ADD  CONSTRAINT [CK_Dostawcy_Telefon] CHECK  (([Telefon_kontaktowy] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Dostawcy] CHECK CONSTRAINT [CK_Dostawcy_Telefon]
GO
ALTER TABLE [dbo].[Dostawcy]  WITH CHECK ADD  CONSTRAINT [CK_Dostawcy_Ulica] CHECK  (([Ulica] like '%[0-9][a-z]' OR [Ulica] like '%[0-9]'))
GO
ALTER TABLE [dbo].[Dostawcy] CHECK CONSTRAINT [CK_Dostawcy_Ulica]
GO
ALTER TABLE [dbo].[Dostawy]  WITH CHECK ADD  CONSTRAINT [CK_Dostawy_Daty] CHECK  (([Data_dostawy] IS NULL OR [Data_dostawy]>=[Data_zamówienia]))
GO
ALTER TABLE [dbo].[Dostawy] CHECK CONSTRAINT [CK_Dostawy_Daty]
GO
ALTER TABLE [dbo].[Kategorie]  WITH CHECK ADD  CONSTRAINT [CK_Kategorie_Nazwa] CHECK  ((len([Nazwa_kategorii])>(2)))
GO
ALTER TABLE [dbo].[Kategorie] CHECK CONSTRAINT [CK_Kategorie_Nazwa]
GO
ALTER TABLE [dbo].[Klienci]  WITH CHECK ADD  CONSTRAINT [CK_Klienci_Email] CHECK  (([Email] like '%@%.%'))
GO
ALTER TABLE [dbo].[Klienci] CHECK CONSTRAINT [CK_Klienci_Email]
GO
ALTER TABLE [dbo].[Klienci]  WITH CHECK ADD  CONSTRAINT [CK_Klienci_Telefon] CHECK  (([Telefon_kontaktowy] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Klienci] CHECK CONSTRAINT [CK_Klienci_Telefon]
GO
ALTER TABLE [dbo].[Klienci_Biz]  WITH CHECK ADD  CONSTRAINT [CK_Klienci_Biz_Kod_pocztowy] CHECK  (([Kod_pocztowy] like '[0-9][0-9][0-9][0-9][0-9]' OR [Kod_pocztowy] like '[0-9][0-9]-[0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Klienci_Biz] CHECK CONSTRAINT [CK_Klienci_Biz_Kod_pocztowy]
GO
ALTER TABLE [dbo].[Klienci_Biz]  WITH CHECK ADD  CONSTRAINT [CK_Klienci_Biz_NIP] CHECK  (([NIP] like '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'))
GO
ALTER TABLE [dbo].[Klienci_Biz] CHECK CONSTRAINT [CK_Klienci_Biz_NIP]
GO
ALTER TABLE [dbo].[Klienci_Biz]  WITH CHECK ADD  CONSTRAINT [CK_Klienci_Biz_Ulica] CHECK  (([Ulica] like '%[0-9][a-z]' OR [Ulica] like '%[0-9]'))
GO
ALTER TABLE [dbo].[Klienci_Biz] CHECK CONSTRAINT [CK_Klienci_Biz_Ulica]
GO
ALTER TABLE [dbo].[Klienci_Ind]  WITH CHECK ADD  CONSTRAINT [CK_Klienci_Ind_Imie] CHECK  ((NOT [Imię] like '%[0-9]%'))
GO
ALTER TABLE [dbo].[Klienci_Ind] CHECK CONSTRAINT [CK_Klienci_Ind_Imie]
GO
ALTER TABLE [dbo].[Klienci_Ind]  WITH CHECK ADD  CONSTRAINT [CK_Klienci_Ind_Nazw] CHECK  ((NOT [Nazwisko] like '%[0-9]%'))
GO
ALTER TABLE [dbo].[Klienci_Ind] CHECK CONSTRAINT [CK_Klienci_Ind_Nazw]
GO
ALTER TABLE [dbo].[Miasta]  WITH CHECK ADD  CONSTRAINT [CK_Miasta_Nazwa] CHECK  ((len([Nazwa_miasta])>(1)))
GO
ALTER TABLE [dbo].[Miasta] CHECK CONSTRAINT [CK_Miasta_Nazwa]
GO
ALTER TABLE [dbo].[Obostrzenia]  WITH CHECK ADD  CONSTRAINT [CK_Obostrzenia_Liczba_Miejsc] CHECK  (([Liczba_miejsc]>=(0)))
GO
ALTER TABLE [dbo].[Obostrzenia] CHECK CONSTRAINT [CK_Obostrzenia_Liczba_Miejsc]
GO
ALTER TABLE [dbo].[Obsluga]  WITH CHECK ADD  CONSTRAINT [CK_Obsługa_Imie] CHECK  ((NOT [Imię] like '%[0-9]%'))
GO
ALTER TABLE [dbo].[Obsluga] CHECK CONSTRAINT [CK_Obsługa_Imie]
GO
ALTER TABLE [dbo].[Obsluga]  WITH CHECK ADD  CONSTRAINT [CK_Obsługa_Nazwisko] CHECK  ((NOT [Nazwisko] like '%[0-9]%'))
GO
ALTER TABLE [dbo].[Obsluga] CHECK CONSTRAINT [CK_Obsługa_Nazwisko]
GO
ALTER TABLE [dbo].[Przepisy]  WITH CHECK ADD  CONSTRAINT [CK_Przepisy_Ilosc] CHECK  (([Potrzebna_ilość]>(0)))
GO
ALTER TABLE [dbo].[Przepisy] CHECK CONSTRAINT [CK_Przepisy_Ilosc]
GO
ALTER TABLE [dbo].[Rabaty]  WITH CHECK ADD  CONSTRAINT [CK_Rabaty_Wymagana_Kwota] CHECK  (([Wymagana_kwota]>(0)))
GO
ALTER TABLE [dbo].[Rabaty] CHECK CONSTRAINT [CK_Rabaty_Wymagana_Kwota]
GO
ALTER TABLE [dbo].[Rabaty]  WITH CHECK ADD  CONSTRAINT [CK_Rabaty_Wys_Jedn] CHECK  (([Wysokosc_jedn]>=(0) AND [Wysokosc_jedn]<=(1)))
GO
ALTER TABLE [dbo].[Rabaty] CHECK CONSTRAINT [CK_Rabaty_Wys_Jedn]
GO
ALTER TABLE [dbo].[Rabaty_Firm_Miesiac]  WITH CHECK ADD  CONSTRAINT [CK_Rabaty_Firm_Miesiac_L_Zam] CHECK  (([Liczba_zamowien]>(0)))
GO
ALTER TABLE [dbo].[Rabaty_Firm_Miesiac] CHECK CONSTRAINT [CK_Rabaty_Firm_Miesiac_L_Zam]
GO
ALTER TABLE [dbo].[Rabaty_Firm_Miesiac]  WITH CHECK ADD  CONSTRAINT [CK_Rabaty_Firm_Miesiac_Max_Rabat] CHECK  (([Max_rabat]>=(0) AND [Max_rabat]<=(1)))
GO
ALTER TABLE [dbo].[Rabaty_Firm_Miesiac] CHECK CONSTRAINT [CK_Rabaty_Firm_Miesiac_Max_Rabat]
GO
ALTER TABLE [dbo].[Rabaty_Ind_Jednorazowe]  WITH CHECK ADD  CONSTRAINT [CK_Rabaty_Ind_Jednorazowe_Waznosc] CHECK  (([Waznosc]>(0)))
GO
ALTER TABLE [dbo].[Rabaty_Ind_Jednorazowe] CHECK CONSTRAINT [CK_Rabaty_Ind_Jednorazowe_Waznosc]
GO
ALTER TABLE [dbo].[Rabaty_Ind_Stale]  WITH CHECK ADD  CONSTRAINT [CK_Rabaty_Ind_Stale_L_Zam] CHECK  (([Liczba_zamowien]>(0)))
GO
ALTER TABLE [dbo].[Rabaty_Ind_Stale] CHECK CONSTRAINT [CK_Rabaty_Ind_Stale_L_Zam]
GO
ALTER TABLE [dbo].[Restauracje]  WITH CHECK ADD  CONSTRAINT [CK_Restauracje_Ulica] CHECK  (([Ulica] like '%[0-9][a-z]' OR [Ulica] like '%[0-9]'))
GO
ALTER TABLE [dbo].[Restauracje] CHECK CONSTRAINT [CK_Restauracje_Ulica]
GO
ALTER TABLE [dbo].[Stan_Magazynowy]  WITH CHECK ADD  CONSTRAINT [CK_Stan_Magazynowy] CHECK  (([Stan_magazynowy]>=(0)))
GO
ALTER TABLE [dbo].[Stan_Magazynowy] CHECK CONSTRAINT [CK_Stan_Magazynowy]
GO
ALTER TABLE [dbo].[Stoliki]  WITH CHECK ADD  CONSTRAINT [CK_Stoliki_Liczba_Miejsc] CHECK  (([Max_liczba_miejsc]>(0)))
GO
ALTER TABLE [dbo].[Stoliki] CHECK CONSTRAINT [CK_Stoliki_Liczba_Miejsc]
GO
ALTER TABLE [dbo].[Szczegóły_Dostaw]  WITH CHECK ADD  CONSTRAINT [CK_Szczegóły_Dostaw_Ilosc_Jedn] CHECK  (([Ilość_jednostek]>(0)))
GO
ALTER TABLE [dbo].[Szczegóły_Dostaw] CHECK CONSTRAINT [CK_Szczegóły_Dostaw_Ilosc_Jedn]
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień]  WITH CHECK ADD  CONSTRAINT [CK_Szczegóły_Zamówień_cena] CHECK  (([Cena_jednostkowa]>(0)))
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień] CHECK CONSTRAINT [CK_Szczegóły_Zamówień_cena]
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień]  WITH CHECK ADD  CONSTRAINT [CK_Szczegóły_Zamówień_ilość] CHECK  (([Ilość]>(0)))
GO
ALTER TABLE [dbo].[Szczegóły_Zamówień] CHECK CONSTRAINT [CK_Szczegóły_Zamówień_ilość]
GO
ALTER TABLE [dbo].[Zamówienia]  WITH CHECK ADD  CONSTRAINT [CK_Zamówienia_Na_wynos] CHECK  (([Na_wynos] like '[TN]'))
GO
ALTER TABLE [dbo].[Zamówienia] CHECK CONSTRAINT [CK_Zamówienia_Na_wynos]
GO
/****** Object:  StoredProcedure [dbo].[Aktualizuj_Cene_Dania]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Aktualizuj_Cene_Dania]
	-- Add the parameters for the stored procedure here
	@nazwa_dania varchar(50),
	@nowa_cena money
AS
BEGIN
	DECLARE @id_dania int = (SELECT ID_dania FROM dbo.Dania WHERE @nazwa_dania=Nazwa_dania)
	IF @id_dania IS NULL
	BEGIN
	;THROW 52000, 'Podane danie nie istnieje!',1
	END
	ELSE
	BEGIN
	UPDATE dbo.Dania SET Cena_dania=@nowa_cena WHERE ID_dania=@id_dania
	PRINT 'Zaktualizowano pomyślnie.'
	END
	SET NOCOUNT ON;

 
END
GO
/****** Object:  StoredProcedure [dbo].[Aktualizuj_Rabat_Firm_Kwartalny]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Aktualizuj_Rabat_Firm_Kwartalny]
	@id_klienta int,
	@id_restauracji int
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @id_rabatu int =(SELECT r.ID_rabatu FROM Rabaty r
	INNER JOIN Rabaty_Firm_Miesiac rf ON rf.ID_rabatu=r.ID_rabatu
	WHERE ID_Restauracji=@id_restauracji AND Data_zdjęcia IS NULL)

	IF @id_rabatu IS NOT NULL AND NOT EXISTS (SELECT * FROM Aktualnie_Przyznane_Rabaty WHERE ID_klienta=@id_klienta AND @id_rabatu=ID_rabatu)
	BEGIN
		DECLARE @laczna_wart_zam money = (SELECT SUM(sz.Ilość*sz.Cena_jednostkowa) FROM Szczegóły_Zamówień sz
		INNER JOIN Zamówienia z ON z.ID_zamówienia=sz.ID_zamówienia
		WHERE @id_klienta=z.ID_klienta AND DATEDIFF(day,z.Data_zamówienia,GETDATE())<=91)

		DECLARE @wymagana_kwota money=(SELECT Wymagana_kwota FROM Rabaty WHERE ID_rabatu=@id_rabatu)
		
		IF @laczna_wart_zam>=@wymagana_kwota
		BEGIN
			EXEC Przyznaj_Rabat_Klientowi
			@id_rabatu,
			@id_klienta,
			null,
			null
		END
	END

END
GO
/****** Object:  StoredProcedure [dbo].[Aktualizuj_Rabat_Firm_Miesieczny]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Aktualizuj_Rabat_Firm_Miesieczny]
	@id_klienta int,
	@id_restauracji int
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @id_rabatu int =(SELECT r.ID_rabatu FROM Rabaty r
	INNER JOIN Rabaty_Firm_Miesiac rf ON rf.ID_rabatu=r.ID_rabatu
	WHERE ID_Restauracji=@id_restauracji AND Data_zdjęcia IS NULL)

	IF @id_rabatu IS NOT NULL AND NOT EXISTS (SELECT * FROM Aktualnie_Przyznane_Rabaty WHERE ID_klienta=@id_klienta AND @id_rabatu=ID_rabatu)
	BEGIN
		DECLARE @laczna_wart_zam money = (SELECT SUM(sz.Ilość*sz.Cena_jednostkowa) FROM Szczegóły_Zamówień sz
		INNER JOIN Zamówienia z ON z.ID_zamówienia=sz.ID_zamówienia
		WHERE @id_klienta=z.ID_klienta AND DATEDIFF(day,z.Data_zamówienia,GETDATE())<=30)

		DECLARE @wymagana_kwota money=(SELECT Wymagana_kwota FROM Rabaty WHERE ID_rabatu=@id_rabatu)

		DECLARE @wymagana_ilosc_zam int =(SELECT Liczba_zamowien FROM Rabaty_Firm_Miesiac WHERE ID_rabatu=@id_rabatu)

		DECLARE @ilosc_zam int =(SELECT COUNT(*) FROM Zamówienia WHERE ID_klienta=@id_klienta AND DATEDIFF(day,Data_zamówienia,GETDATE())<=30)
		
		IF @laczna_wart_zam>=@wymagana_kwota AND @ilosc_zam>=@wymagana_ilosc_zam
		BEGIN
			EXEC Przyznaj_Rabat_Klientowi
			@id_rabatu,
			@id_klienta,
			null,
			null
		END
	END

END
GO
/****** Object:  StoredProcedure [dbo].[Aktualizuj_Rabat_Ind_Jednorazowy]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Aktualizuj_Rabat_Ind_Jednorazowy]
	@id_klienta int,
	@id_restauracji int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @id_rabatu int =(SELECT r.ID_rabatu FROM Rabaty r
	INNER JOIN Rabaty_Ind_Jednorazowe rj ON rj.ID_rabatu=r.ID_rabatu
	WHERE ID_Restauracji=@id_restauracji AND Data_zdjęcia IS NULL)

	IF @id_rabatu IS NOT NULL AND NOT EXISTS (SELECT * FROM Aktualnie_Przyznane_Rabaty WHERE ID_klienta=@id_klienta AND @id_rabatu=ID_rabatu)
	BEGIN
		DECLARE @laczna_wart_zam money = (SELECT SUM(sz.Ilość*sz.Cena_jednostkowa) FROM Szczegóły_Zamówień sz
		INNER JOIN Zamówienia z ON z.ID_zamówienia=sz.ID_zamówienia
		WHERE @id_klienta=z.ID_klienta)

		DECLARE @wymagana_kwota money=(SELECT Wymagana_kwota FROM Rabaty WHERE ID_rabatu=@id_rabatu)
		
		IF @laczna_wart_zam>=@wymagana_kwota
		BEGIN
			EXEC Przyznaj_Rabat_Klientowi
			@id_rabatu,
			@id_klienta,
			null,
			null
		END
	END
END
GO
/****** Object:  StoredProcedure [dbo].[Aktualizuj_Rabat_Ind_Staly]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Aktualizuj_Rabat_Ind_Staly]
	@id_klienta int,
	@id_restauracji int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @id_rabatu int =(SELECT r.ID_rabatu FROM Rabaty r
	INNER JOIN Rabaty_Ind_Stale ri ON ri.ID_rabatu=r.ID_rabatu
	WHERE ID_Restauracji=@id_restauracji AND Data_zdjęcia IS NULL)

	IF @id_rabatu IS NOT NULL AND NOT EXISTS (SELECT * FROM Aktualnie_Przyznane_Rabaty WHERE ID_klienta=@id_klienta AND @id_rabatu=ID_rabatu)
	BEGIN
		DECLARE @liczba_zamowien int = (SELECT Liczba_zamowien FROM Rabaty_Ind_Stale WHERE ID_rabatu=@id_rabatu)
		DECLARE @wymagana_kwota money = (SELECT Wymagana_kwota FROM Rabaty WHERE ID_rabatu=@id_rabatu)
		DECLARE @ilosc_powyzej_kwoty int =(SELECT dbo.Ilosc_Zamowien_Powyzej_Kwoty(@id_restauracji,@id_klienta,@wymagana_kwota))
		IF (@ilosc_powyzej_kwoty>=@liczba_zamowien)
		BEGIN
			EXEC Przyznaj_Rabat_Klientowi
				@id_rabatu,
				@id_klienta,
				null,
				null
		END
	END
END
GO
/****** Object:  StoredProcedure [dbo].[Anuluj_Rezerwacje]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Anuluj_Rezerwacje]
	@id_rezerwacji int
AS
BEGIN
	SET NOCOUNT ON;
	DELETE FROM Rezerwacje_Ind WHERE ID_rezerwacji=@id_rezerwacji
	DELETE FROM Rezerwacje_Firm WHERE ID_rezerwacji=@id_rezerwacji
	DELETE FROM Rezerwacje_Firm_Imiennie WHERE ID_rezerwacji=@id_rezerwacji
	DELETE FROM Szczegóły_Rezerwacji WHERE ID_rezerwacji=@id_rezerwacji
	DELETE FROM Rezerwacje WHERE ID_rezerwacji=@id_rezerwacji
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Danie]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Danie]
   	@nazwa_dania varchar(50),
    @cena money,
	@nazwa_kategorii varchar(50),
	@opis varchar(255)=null
AS
BEGIN
   	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Danie
			IF NOT EXISTS(SELECT * FROM Kategorie WHERE Nazwa_kategorii=@nazwa_kategorii)
			BEGIN
				INSERT INTO Kategorie(Nazwa_kategorii) VALUES (@nazwa_kategorii)
			END
			DECLARE @id_kategorii int = (SELECT ID_kategorii FROM Kategorie WHERE Nazwa_kategorii=@nazwa_kategorii)
			IF @cena<=0
			BEGIN
				;THROW 52000, 'Cena musi byc wartoscia dodatnia',1
			END
			INSERT INTO Dania(Nazwa_dania,Cena_dania,Kategoria,Opis_dania)
			VALUES (@nazwa_dania,@cena,@id_kategorii,@opis)
    	COMMIT TRAN Dodaj_Danie
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Danie
        	DECLARE @errorMsg nvarchar (2048) = 'Blad dodania nowego dania: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Do_Magazynu]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Do_Magazynu]
   	@nazwa_restauracji varchar(50),
	@nazwa_produktu varchar(50),
	@ilosc_jednostek float 
AS
BEGIN
   	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Do_Magazynu
			IF NOT EXISTS (SELECT * FROM Polprodukty WHERE @nazwa_produktu=Nazwa)
			BEGIN
				EXEC Dodaj_Polprodukt
					@nazwa_produktu
			END
			IF @ilosc_jednostek<=0
			BEGIN
				;THROW 52000, 'Liczba dodawanych jednostek musi byc wieksza od 0',1
			END
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			BEGIN
				;THROW 52000, 'Nie istnieje taka restauracja',1
			END
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			DECLARE @id_produktu int = (SELECT ID_półproduktu FROM Polprodukty WHERE Nazwa=@nazwa_produktu)
			IF EXISTS(SELECT * FROM Stan_Magazynowy WHERE ID_restauracji=@id_restauracji
			AND @id_produktu=ID_półproduktu)
			BEGIN
				UPDATE Stan_Magazynowy SET Stan_magazynowy=Stan_magazynowy+@ilosc_jednostek
				WHERE ID_restauracji=@id_restauracji AND @id_produktu=ID_półproduktu
			END
			ELSE
			BEGIN
				INSERT INTO Stan_Magazynowy(ID_półproduktu,ID_restauracji,Stan_magazynowy)
				VALUES (@id_produktu,@id_restauracji,@ilosc_jednostek)
			END
    	COMMIT TRAN Dodaj_Do_Magazynu
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Do_Magazynu
        	DECLARE @errorMsg nvarchar (2048) = 'Blad zwiekszenia ilosci jednostek w magazynie: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Do_Menu]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Do_Menu]
	@nazwa_dania varchar(50),
	@data_wprowadzenia date,
	@nazwa_restauracji varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
        BEGIN TRAN Dodaj_Do_Menu 
			IF NOT EXISTS (SELECT * FROM Dania WHERE Nazwa_dania=@nazwa_dania)
			BEGIN 
				;THROW 52000, 'Nie ma takiego dania',1
			END
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			BEGIN
				;THROW 52000, 'Nie ma takiej restauracji',1
			END
			DECLARE @id_dania int = (SELECT ID_dania FROM Dania WHERE Nazwa_dania=@nazwa_dania)
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			IF NOT EXISTS (SELECT * FROM Menu WHERE @id_dania=ID_dania AND ID_restauracji=@id_restauracji)
			BEGIN
				INSERT INTO Menu(ID_dania,Data_wprowadzenia,ID_restauracji)
				VALUES (@id_dania,@data_wprowadzenia,@id_restauracji)
			END
			ELSE IF (SELECT dbo.Ostatnie_Usuniecie_Z_Menu(@id_dania,@id_restauracji)) IS NULL
			BEGIN
				;THROW 52000, 'Nie mozna dodac do menu, poniewaz jest w menu',1
			END
			ELSE IF (SELECT dbo.Ostatnie_Usuniecie_Z_Menu(@id_dania,@id_restauracji))>@data_wprowadzenia
			BEGIN
				;THROW 52000, 'Danie nie moze zostac znow dodane przed data jego ostatniego usuniecia',1
			END
			ELSE IF (DATEDIFF(DAY,(SELECT dbo.Ostatnie_Usuniecie_Z_Menu(@id_dania,@id_restauracji)),@data_wprowadzenia)<30)
			BEGIN
				;THROW 52000, 'Nie mozna dodac do menu, poniewaz nie minal miesiac od zdjecia',1
			END
			ELSE
			BEGIN
				INSERT INTO Menu(ID_dania,Data_wprowadzenia,ID_restauracji)
				VALUES (@id_dania,@data_wprowadzenia,@id_restauracji)
			END
        COMMIT TRAN Dodaj_Do_Menu
    END TRY
    BEGIN CATCH
            ROLLBACK TRAN Dodaj_Do_Menu
            DECLARE @errorMsg nvarchar (2048) = 'Blad dodania do menu: '+ ERROR_MESSAGE () ;
        THROW 52000 , @errorMsg ,1;
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Dostawce]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Dostawce]
	@nazwa_firmy varchar(50),
	@ulica varchar(50),
	@kod varchar(6),
	@miasto varchar(50),
	@panstwo varchar(50),
	@telefon varchar(9)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Dodaj_Dostawce
			IF EXISTS (SELECT * FROM Dostawcy WHERE Telefon_kontaktowy=@telefon) OR
				EXISTS (SELECT * FROM Klienci WHERE Telefon_kontaktowy=@telefon)
			BEGIN
				;THROW 52000, 'Telefon musi byc unikalny',1
			END
			IF NOT EXISTS (SELECT * FROM Miasta WHERE Nazwa_miasta=@miasto)
			BEGIN
				EXEC Dodaj_Miasto
					@miasto,
					@panstwo
			END
			DECLARE @id_miasta int =(SELECT ID_miasta FROM Miasta WHERE Nazwa_miasta=@miasto)
			INSERT INTO Dostawcy(Nazwa_firmy,Ulica,Kod_pocztowy,ID_miasta,Telefon_kontaktowy)
			VALUES (@nazwa_firmy,@ulica,@kod,@id_miasta,@telefon)
		COMMIT TRAN Dodaj_Dostawce
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Dodaj_Dostawce
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania dostawcy: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Dostawe]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Dostawe]
   	@nazwa_restauracji varchar(50),
	@nazwa_dostawcy varchar(50),
	@data_zamowienia date
AS
BEGIN
   	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Dostawe
			IF NOT EXISTS (SELECT * FROM Dostawcy WHERE @nazwa_dostawcy=Nazwa_firmy)
			BEGIN
				;THROW 52000, 'Nie istnieje taki dostawca',1
			END
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			BEGIN
				;THROW 52000, 'Nie istnieje taka restauracja',1
			END
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			DECLARE @id_dostawcy int = (SELECT ID_dostawcy FROM Dostawcy WHERE Nazwa_firmy=@nazwa_dostawcy)
			INSERT INTO Dostawy(ID_dostawcy,Data_zamówienia,Data_dostawy,ID_Restauracji)
			VALUES (@id_dostawcy,@data_zamowienia,null,@id_restauracji)
    	COMMIT TRAN Dodaj_Dostawe
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Dostawe
        	DECLARE @errorMsg nvarchar (2048) = 'Blad dodawania dostawy: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Element_Do_Zamowienia]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Element_Do_Zamowienia]
	@id_zamowienia int,
	@nazwa_restauracji varchar(50),
	@nazwa_dania varchar(50),
	@ilosc int
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
    	BEGIN TRAN Dodaj_Element
			IF @nazwa_restauracji <> (
				SELECT r.Nazwa FROM Restauracje r
				INNER JOIN Obsluga o ON o.ID_Restauracji=r.ID_restauracji
				INNER JOIN Zamówienia z ON z.Pracownik_obsługujący=o.ID_pracownika
				WHERE @id_zamowienia=z.ID_zamówienia)
			BEGIN
				;THROW 52000, 'Proba dostania sie do danych innego lokalu',1
			END
			IF NOT EXISTS (SELECT * FROM Zamówienia WHERE ID_zamówienia=@id_zamowienia)
			BEGIN 
				;THROW 52000, 'Nie ma takiego zamowienia',1
			END
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			BEGIN
				;THROW 52000, 'Nie istnieje taka restauracja',1
			END
			IF NOT EXISTS (SELECT * FROM Dania WHERE @nazwa_dania=Nazwa_dania)
			BEGIN
				;THROW 52000, 'Nie ma takiego dania',1
			END
			IF @ilosc<=0
			BEGIN
				;THROW 52000, 'Trzeba zamowic przynajmniej jedna sztuke',1
			END
			DECLARE @id_dania int = (SELECT ID_dania FROM Dania WHERE Nazwa_dania=@nazwa_dania)
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			IF (SELECT Kategoria FROM Dania WHERE @id_dania=ID_dania) = (SELECT ID_kategorii FROM Kategorie WHERE Nazwa_kategorii='Seafood')
			BEGIN
				DECLARE @data_odbioru date =(SELECT Data_odbioru FROM Zamówienia WHERE @id_zamowienia=ID_zamówienia)
				DECLARE @data_zamowienia date =(SELECT Data_zamówienia FROM Zamówienia WHERE @id_zamowienia=ID_zamówienia)
				IF(DATEPART(w,@data_odbioru)=5 AND DATEDIFF(day,@data_zamowienia,@data_odbioru)<3)
				BEGIN
					;THROW 52000, 'Niespelnione warunki na danie z kategorii owoce morza',1
				END
				IF(DATEPART(w,@data_odbioru)=6 AND DATEDIFF(day,@data_zamowienia,@data_odbioru)<4)
				BEGIN
					;THROW 52000, 'Niespelnione warunki na danie z kategorii owoce morza',1
				END
				IF(DATEPART(w,@data_odbioru)=7 AND DATEDIFF(day,@data_zamowienia,@data_odbioru)<5)
				BEGIN
					;THROW 52000, 'Niespelnione warunki na danie z kategorii owoce morza',1
				END
			END
			IF NOT EXISTS (SELECT ID_pozycji FROM Menu WHERE ID_dania=@id_dania
			AND ID_restauracji=@id_restauracji AND Data_zdjęcia is NULL)
			BEGIN
				;THROW 52000, 'To danie nie jest obecnie w ofercie restauracji',1
			END
			DECLARE @id_pozycji int =(SELECT ID_pozycji FROM Menu WHERE ID_dania=@id_dania
			AND ID_restauracji=@id_restauracji AND Data_zdjęcia is NULL)
			DECLARE iter CURSOR
			FOR 
				SELECT ID_półproduktu
				FROM Przepisy
				WHERE @id_dania=ID_dania
			DECLARE @id_polproduktu int
			OPEN iter
			FETCH NEXT FROM iter INTO @id_polproduktu
			WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE @nazwa_polproduktu varchar(50)=(SELECT Nazwa FROM Polprodukty WHERE @id_polproduktu=ID_półproduktu)
				PRINT @nazwa_polproduktu
				DECLARE @ilosc_jednostek float =(SELECT Potrzebna_ilość FROM Przepisy WHERE ID_dania=@id_dania
					AND @id_polproduktu=ID_półproduktu)*@ilosc
				EXEC Pobierz_Z_Magazynu
					@nazwa_restauracji,
					@nazwa_polproduktu,
					@ilosc_jednostek
				FETCH NEXT FROM iter INTO @id_polproduktu
			END
			CLOSE iter
			DEALLOCATE iter
			DECLARE @rabat float=0.0
			DECLARE @id_klienta int =(SELECT ID_klienta FROM Zamówienia WHERE ID_zamówienia=@id_zamowienia)
			IF @id_klienta IN (SELECT ID_klienta FROM Klienci_Ind)
			BEGIN
				SET @rabat=@rabat+dbo.Nalicz_Rabat_Ind_Staly(@id_restauracji,@id_klienta)+dbo.Nalicz_Rabat_Ind_Jednorazowy(@id_restauracji,@id_klienta)
				IF @id_klienta IN (SELECT ID_pracownika FROM Pracownicy_Firm)
				BEGIN
					DECLARE @id_firmy int = (SELECT TOP 1 ID_firmy FROM Pracownicy_Firm WHERE ID_pracownika=@id_klienta)
					SET @rabat=@rabat+dbo.Nalicz_Rabat_Firm_Miesieczny(@id_restauracji,@id_firmy)+dbo.Nalicz_Rabat_Firm_Kwartalny(@id_restauracji,@id_firmy)
				END
			END
			ELSE
			BEGIN
				SET @rabat=@rabat+dbo.Nalicz_Rabat_Firm_Miesieczny(@id_restauracji,@id_klienta)+dbo.Nalicz_Rabat_Firm_Kwartalny(@id_restauracji,@id_klienta)
			END
			IF @rabat>1
			BEGIN
				SET @rabat=1
			END
			DECLARE @cena money = (SELECT Cena_dania FROM Dania WHERE ID_dania=@id_dania)*(1-@rabat)
			INSERT INTO Szczegóły_Zamówień(ID_zamówienia,ID_pozycji,Cena_jednostkowa,Ilość)
			VALUES(@id_zamowienia,@id_pozycji,@cena,@ilosc)
			COMMIT TRAN Dodaj_Element
	END TRY
	BEGIN CATCH
        ROLLBACK TRAN Dodaj_Element
        	DECLARE @errorMsg nvarchar (2048) = 'Blad przy dodaniu dania do zamowienia: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Element_Przepisu]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Element_Przepisu]
   	@nazwa_dania varchar(50),
	@nazwa_produktu varchar(50),
	@potrzebna_ilosc float
AS
BEGIN
   	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Skladnik
			IF NOT EXISTS (SELECT * FROM Dania WHERE Nazwa_dania=@nazwa_dania)
			BEGIN
				;THROW 52000, 'Nie ma takiego dania',1
			END
			IF @potrzebna_ilosc<=0
			BEGIN
				;THROW 52000, 'Potrzebna ilosc skladnika musi byc liczba dodatnia',1
			END
			IF NOT EXISTS (SELECT * FROM Polprodukty WHERE Nazwa=@nazwa_produktu)
			BEGIN
				EXEC Dodaj_Polprodukt
					@nazwa_produktu
			END
			DECLARE @id_dania int =(SELECT ID_dania FROM Dania WHERE @nazwa_dania=Nazwa_dania)
			DECLARE @id_polproduktu int = (SELECT ID_półproduktu FROM Polprodukty WHERE @nazwa_produktu=Nazwa)
			INSERT INTO Przepisy (ID_dania,ID_półproduktu,Potrzebna_ilość)
			VALUES(@id_dania,@id_polproduktu,@potrzebna_ilosc)
    	COMMIT TRAN Dodaj_Skladnik
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Skladnik
        	DECLARE @errorMsg nvarchar (2048) = 'Blad dodania skladnika: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Klienta]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Klienta]
	@email varchar(50),
	@telefon varchar(9)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF EXISTS(
			SELECT * FROM Klienci
			WHERE Email=@email
		)
		BEGIN
		 ;THROW 52000, 'Email jest juz zajety',1
		END
		IF EXISTS(
			SELECT * FROM Klienci
			WHERE Telefon_kontaktowy=@telefon
		)
		BEGIN
		 ;THROW 52000, 'Telefon jest juz zajety',1
		END
		INSERT INTO Klienci(Telefon_kontaktowy,Email)
		VALUES (@telefon,@email)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania klienta: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Klienta_Biz]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Klienta_Biz]
	@email varchar(50),
	@telefon varchar(9),
	@nazwa_firmy varchar(50),
	@nip varchar(10),
	@ulica varchar(50),
	@kod varchar(6),
	@nazwa_miasta varchar(50),
	@nazwa_panstwa varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Dodaj_Klienta_Biz
			EXEC dbo.Dodaj_Klienta
				@email,
				@telefon
			DECLARE @id int = @@IDENTITY
			IF EXISTS(SELECT * FROM Miasta WHERE Nazwa_miasta=@nazwa_miasta)
				BEGIN
					DECLARE @id_miasta int = (SELECT ID_miasta FROM Miasta WHERE Nazwa_miasta=@nazwa_miasta)
					INSERT INTO Klienci_Biz(ID_klienta,Nazwa_firmy,NIP,Ulica,Kod_pocztowy,ID_miasta)
					VALUES (@id,@nazwa_firmy,@nip,@ulica,@kod,@id_miasta)
				END
			ELSE
				BEGIN
					EXEC dbo.Dodaj_Miasto
						@nazwa_miasta,
						@nazwa_panstwa
					INSERT INTO Klienci_Biz(ID_klienta,Nazwa_firmy,NIP,Ulica,Kod_pocztowy,ID_miasta)
					VALUES (@id,@nazwa_firmy,@nip,@ulica,@kod,@@IDENTITY)
				END
		COMMIT TRAN Dodaj_Klienta_Biz
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Dodaj_Klienta_Biz
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania klienta biznesowego: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Klienta_Ind]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Klienta_Ind]
	@imię varchar(30),
	@nazwisko varchar(30),
	@email varchar(50),
	@telefon varchar(9)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Dodaj_Klienta_Ind
			EXEC dbo.Dodaj_Klienta
				@email,
				@telefon
			DECLARE @id int = @@IDENTITY
			INSERT INTO Klienci_Ind(ID_klienta,Imię,Nazwisko)
			VALUES (@id,@imię,@nazwisko)
		COMMIT TRAN Dodaj_Klienta_Ind
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Dodaj_Klienta_Ind
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania klienta indywidualnego: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Lokal]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Lokal]
	@nazwa_lokalu varchar(50),
	@ulica varchar(50),
	@nazwa_miasta varchar(50),
	@nazwa_panstwa varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS(
			SELECT * FROM Miasta WHERE Nazwa_miasta=@nazwa_miasta
		)
		BEGIN
			EXEC Dodaj_Miasto
				@nazwa_miasta,
				@nazwa_panstwa
		END
		DECLARE @id_miasta int = (SELECT ID_miasta FROM Miasta WHERE @nazwa_miasta=Nazwa_miasta)
		INSERT INTO Restauracje(Nazwa,Ulica,Miasto) VALUES (@nazwa_lokalu,@ulica,@id_miasta)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania restauracji: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Miasto]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Miasto]
	@nazwa_miasta varchar(50),
	@nazwa_panstwa varchar(50)
AS
BEGIN
	IF EXISTS (SELECT * FROM Panstwa WHERE Panstwa.Nazwa=@nazwa_panstwa)
		BEGIN
			DECLARE @id_panstwa int = (SELECT ID_państwa FROM Panstwa WHERE Panstwa.Nazwa=@nazwa_panstwa)
			INSERT INTO Miasta(Nazwa_miasta,ID_państwa) VALUES (@nazwa_miasta,@id_panstwa)
		END
	ELSE
		BEGIN
			EXEC dbo.Dodaj_Panstwo
				@nazwa_panstwa
			INSERT INTO Miasta(Nazwa_miasta,ID_państwa) VALUES (@nazwa_miasta, @@IDENTITY)
		END	
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Obostrzenie]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Obostrzenie]
	@id_stolika int,
	@liczba_miejsc int,
	@data_wprowadzenia date=null
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS(
			SELECT * FROM Stoliki WHERE ID_stolika=@id_stolika
		)
		BEGIN
			;THROW 52000, 'Nie istnieje taki stolik',1
		END
		IF @liczba_miejsc>(SELECT Max_liczba_miejsc FROM Stoliki WHERE ID_stolika=@id_stolika)
		BEGIN
			;THROW 52000, 'Nie mozna dac wiecej miejsc niz jest przy stoliku bez obostrzen',1
		END 
		IF @liczba_miejsc<0
		BEGIN
			;THROW 52000, 'Liczba miejsc nie moze byc ujemna',1
		END 
		IF @data_wprowadzenia is null
		BEGIN
			SET @data_wprowadzenia=GETDATE()
		END
		INSERT INTO Obostrzenia(ID_stolika,Liczba_miejsc,Data_wprowadzenia)
		VALUES (@id_stolika,@liczba_miejsc,@data_wprowadzenia)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania obostrzenia na stolik: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Panstwo]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Panstwo]
	@nazwa_panstwa varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO Panstwa(Nazwa) VALUES (@nazwa_panstwa)
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Polprodukt]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Polprodukt]
	@nazwa_produktu varchar(50)
AS
BEGIN
   	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Polprodukt
			IF EXISTS (SELECT * FROM Polprodukty WHERE Nazwa=@nazwa_produktu)
			BEGIN 
				;THROW 52000, 'Półprodukt o takiej nazwie jest już wpisany',1
			END
			INSERT INTO Polprodukty(Nazwa) VALUES (@nazwa_produktu)
    	COMMIT TRAN Dodaj_Polprodukt
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Polprodukt
        	DECLARE @errorMsg nvarchar (2048) = 'Blad przy dodawaniu polproduktu: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Pracownika]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Pracownika]
	@imie varchar(30),
	@nazwisko varchar(30),
	@nazwa_restauracji varchar(50),
	@ulica varchar(50),
	@miasto varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS(
			SELECT * FROM Restauracje r
			INNER JOIN Miasta m
			ON m.ID_miasta=r.Miasto
			WHERE @nazwa_restauracji=r.Nazwa
			AND @ulica=r.Ulica
			AND @miasto=m.Nazwa_miasta
		)
		BEGIN
			;THROW 52000, 'Nie ma takiej restauracji',1
		END
		DECLARE @id_lokalu int = (
			SELECT r.ID_restauracji FROM Restauracje r
			INNER JOIN Miasta m
			ON m.ID_miasta=r.Miasto
			WHERE @nazwa_restauracji=r.Nazwa
			AND @ulica=r.Ulica
			AND @miasto=m.Nazwa_miasta
		)
		INSERT INTO Obsluga(Imię,Nazwisko,ID_Restauracji)
		VALUES (@imie,@nazwisko,@id_lokalu)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania pracownika: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Pracownika_Firmy]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Pracownika_Firmy]
	@imie_pracownika varchar(30),
	@nazwisko_pracownika varchar(30),
	@telefon_pracownika varchar(9),
	@email_pracownika varchar(50),
	@email_firmy varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS (SELECT b.ID_klienta FROM Klienci_Biz b
						INNER JOIN Klienci k ON k.ID_klienta=b.ID_klienta
						where @email_firmy=k.Email)
		BEGIN
			;THROW 52000, 'Nie ma takiej firmy',1
		END
        BEGIN TRAN Dodaj_Pracownika_Firmy
                IF NOT EXISTS (SELECT i.ID_klienta FROM Klienci_Ind i
						INNER JOIN Klienci k ON k.ID_klienta=i.ID_klienta
						where @email_pracownika=k.Email)
				BEGIN
					EXEC dbo.Dodaj_Klienta_Ind
						@imie_pracownika,
						@nazwisko_pracownika,
						@email_pracownika,
						@telefon_pracownika
				END
				DECLARE @id_firmy int = (SELECT ID_klienta FROM Klienci WHERE Email=@email_firmy)
				DECLARE @id_pracownika int = (SELECT ID_klienta FROM Klienci WHERE Email=@email_pracownika)
				INSERT INTO Pracownicy_Firm(ID_firmy,ID_pracownika)
				VALUES (@id_firmy,@id_pracownika)
        COMMIT TRAN Dodaj_Pracownika_Firmy
    END TRY
    BEGIN CATCH
        ROLLBACK TRAN Dodaj_Pracownika_Firmy
        DECLARE @errorMsg nvarchar (2048) = 'Blad dodania pracownika firmy: '+ ERROR_MESSAGE () ;
        THROW 52000 , @errorMsg ,1;
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Produkt_Dostawy]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Produkt_Dostawy]
   	@id_dostawy int,
	@nazwa_polproduktu varchar(50),
	@ilosc_jednostek float
AS
BEGIN
   	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Produkt_Dostawy
			IF NOT EXISTS (SELECT * FROM Dostawy WHERE @id_dostawy=ID_dostawy)
			BEGIN
				;THROW 52000, 'Nie istnieje taka dostawa',1
			END
			IF NOT EXISTS (SELECT * FROM Polprodukty WHERE @nazwa_polproduktu=Nazwa)
			BEGIN
				;THROW 52000, 'Nie istnieje taki polprodukt',1
			END
			DECLARE @id_produktu int =(SELECT ID_półproduktu FROM Polprodukty WHERE @nazwa_polproduktu=Nazwa)
			IF @ilosc_jednostek<=0
			BEGIN
				;THROW 52000, 'Liczba dostarczanych jednostek musi byc wartoscia dodatnia',1
			END
			INSERT INTO Szczegóły_Dostaw(ID_dostawy,ID_półproduktu,Ilość_jednostek)
			VALUES (@id_dostawy,@id_produktu,@ilosc_jednostek)
    	COMMIT TRAN Dodaj_Produkt_Dostawy
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Produkt_Dostawy
        	DECLARE @errorMsg nvarchar (2048) = 'Blad dodawania elementu do dostawy: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rabat]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Rabat]
	@wymagana_kwota money,
	@wysokosc_jedn float,
	@data_wprowadzenia date=null,
	@data_zdjecia date=null,
	@nazwa_restauracji varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
		BEGIN 
			;THROW 52000, 'Nie ma takiej restauracji',1
		END
		DECLARE @id_restauracji int=(SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
		IF @wymagana_kwota<=0
		BEGIN
			;THROW 52000, 'Kwota musi byc wartoscia dodatnia',1
		END
		IF NOT @wysokosc_jedn BETWEEN 0 AND 1
		BEGIN
			;THROW 52000, 'Jednostkowy rabat jest wartoscia z przedzialu od 0 do 1',1
		END
		IF @data_wprowadzenia is NULL
		BEGIN
			SET @data_wprowadzenia=GETDATE()
		END
		INSERT INTO Rabaty(Wymagana_kwota,Wysokosc_jedn,Data_wprowadzenia,Data_zdjęcia,ID_Restauracji)
		VALUES (@wymagana_kwota,@wysokosc_jedn,@data_wprowadzenia,@data_zdjecia,@id_restauracji)
		PRINT 'Dotarlo'
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania rabatu: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rabat_Firm_Kwartal]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Rabat_Firm_Kwartal]
	@wymagana_kwota money,
	@wysokosc_jedn float,
	@data_wprowadzenia date=null,
	@data_zdjecia date=null,
	@nazwa_restauracji varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
		BEGIN 
			;THROW 52000, 'Nie ma takiej restauracji',1
		END
		DECLARE @id_restauracji int=(SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
		IF @wymagana_kwota<=0
		BEGIN
			;THROW 52000, 'Kwota musi byc wartoscia dodatnia',1
		END
		IF NOT @wysokosc_jedn BETWEEN 0 AND 1
		BEGIN
			;THROW 52000, 'Jednostkowy rabat jest wartoscia z przedzialu od 0 do 1',1
		END
		IF @data_wprowadzenia is NULL
		BEGIN
			SET @data_wprowadzenia=GETDATE()
		END
		INSERT INTO Rabaty(Wymagana_kwota,Wysokosc_jedn,Data_wprowadzenia,Data_zdjęcia,ID_Restauracji)
		VALUES (@wymagana_kwota,@wysokosc_jedn,@data_wprowadzenia,@data_zdjecia,@id_restauracji)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania rabatu: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rabat_Firm_Mies]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Dodaj_Rabat_Firm_Mies]
	@wymagana_kwota money,
	@wysokosc_jedn float,
	@data_wprowadzenia date=null,
	@data_zdjecia date=null,
	@nazwa_restauracji varchar(50),
	@liczba_zamowien int,
	@max_rabat float
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Dodaj_Rabat_Firm_Mies
			IF @liczba_zamowien<=0
			BEGIN
				;THROW 52000, 'Minimalna ilosc zamowien musi byc liczba dodatnia calkowita',1
			END
			IF NOT @max_rabat BETWEEN 0 AND 1
			BEGIN
				;THROW 52000, 'Maksymalny mozliwy rabat musi byc liczba pomiedzy 0 a 1',1
			END
			EXEC Dodaj_Rabat
				@wymagana_kwota,
				@wysokosc_jedn,
				@data_wprowadzenia,
				@data_zdjecia,
				@nazwa_restauracji
			DECLARE @id int=@@IDENTITY
			INSERT INTO Rabaty_Firm_Miesiac(ID_rabatu,Liczba_zamowien,Max_rabat)
			VALUES (@id,@liczba_zamowien,@max_rabat)
		COMMIT TRAN Dodaj_Rabat_Firm_Mies
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Dodaj_Rabat_Firm_Mies
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania rabatu: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rabat_Ind_Jednorazowy]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Dodaj_Rabat_Ind_Jednorazowy]
	@wymagana_kwota money,
	@wysokosc_jedn float,
	@data_wprowadzenia date=null,
	@data_zdjecia date=null,
	@nazwa_restauracji varchar(50),
	@waznosc int
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Dodaj_Rabat_Ind_Jedn
			IF @waznosc<=0
			BEGIN
				;THROW 52000, 'Rabat musi miec waznosc przynajmniej 1 dzien',1
			END
			IF @data_wprowadzenia is NULL
			BEGIN
				SET @data_wprowadzenia=GETDATE()
			END
			EXEC Dodaj_Rabat
				@wymagana_kwota,
				@wysokosc_jedn,
				@data_wprowadzenia,
				@data_zdjecia,
				@nazwa_restauracji
			DECLARE @id int = @@IDENTITY
			INSERT INTO Rabaty_Ind_Jednorazowe(ID_rabatu,Waznosc)
			VALUES (@id,@waznosc)
		COMMIT TRAN Dodaj_Rabat_Ind_Jedn
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Dodaj_Rabat_Ind_Jedn
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania rabatu: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rabat_Ind_Staly]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[Dodaj_Rabat_Ind_Staly]
	@wymagana_kwota money,
	@wysokosc_jedn float,
	@data_wprowadzenia date=null,
	@data_zdjecia date=null,
	@nazwa_restauracji varchar(50),
	@liczba_zamowien int
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Dodaj_Rabat_Ind_Staly
			IF @liczba_zamowien<=0
			BEGIN
				;THROW 52000, 'Minimalna ilosc zamowien musi byc liczba dodatnia calkowita',1
			END
			DECLARE @id_restauracji int =(SELECT ID_restauracji FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			DECLARE @id_poprzedniego int = (SELECT ri.ID_rabatu FROM Rabaty_Ind_Stale ri INNER JOIN Rabaty r
						ON r.ID_rabatu=ri.ID_rabatu WHERE r.Data_zdjęcia IS NULL AND @id_restauracji=r.ID_Restauracji)
			IF @id_poprzedniego IS NOT NULL
			BEGIN 
				UPDATE Rabaty SET Data_zdjęcia=@data_wprowadzenia WHERE @id_poprzedniego=ID_rabatu
			END
			EXEC Dodaj_Rabat
				@wymagana_kwota,
				@wysokosc_jedn,
				@data_wprowadzenia,
				@data_zdjecia,
				@nazwa_restauracji
			DECLARE @id_rabatu int=@@IDENTITY
			INSERT INTO Rabaty_Ind_Stale(ID_rabatu,Liczba_zamowien)
			VALUES (@id_rabatu,@liczba_zamowien)
		COMMIT TRAN Dodaj_Rabat_Ind_Staly
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Dodaj_Rabat_Ind_Staly
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania rabatu: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rezerwacje_Firm]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Rezerwacje_Firm]
	@data_zlozenia date,
	@data_rezerwacji date,
	@nazwa_restauracji varchar(50),
	@id_klienta int,
	@liczba_osob int
AS
BEGIN
	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Rezerwacje_Firm
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			BEGIN
				;THROW 52000, 'Nie ma takiej restauracji',1
			END
			DECLARE @id_restauracji int =(SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			DECLARE @liczba_wolnych_miejsc int = dbo.Liczba_Wolnych_Miejsc(@id_restauracji,@data_rezerwacji)
			IF @liczba_wolnych_miejsc<@liczba_osob
			BEGIN
				;THROW 52000, 'Zbyt malo wolnych miejsc',1
			END
			INSERT INTO Rezerwacje(Data_złożenia,Data_rezerwacji,ID_Restauracji)
			VALUES (@data_zlozenia,@data_rezerwacji,@id_restauracji)
			DECLARE @id int=@@IDENTITY
			INSERT INTO Rezerwacje_Firm(ID_rezerwacji,ID_firmy)
			VALUES (@id,@id_klienta)
			DECLARE @liczba_usadzonych int = 0
			WHILE @liczba_usadzonych<@liczba_osob
			BEGIN
				DECLARE @potwierdzenie_stolika int = dbo.Pobierz_Obostrzenie_Do_Rezerwacji(@id_restauracji,@data_rezerwacji)
				DECLARE @zajete int = (SELECT Liczba_miejsc FROM Obostrzenia WHERE ID_Obostrzenia=@potwierdzenie_stolika)
				SET @liczba_usadzonych=@liczba_usadzonych+@zajete
				INSERT INTO Szczegóły_Rezerwacji(ID_rezerwacji,ID_obostrzenia)
				VALUES (@id,@potwierdzenie_stolika)
			END
    	COMMIT TRAN Dodaj_Rezerwacje_Firm
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Rezerwacje_Firm
        	DECLARE @errorMsg nvarchar (2048) = 'Blad dodawania rezerwacji: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rezerwacje_Firm_Im]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Rezerwacje_Firm_Im]
	@data_zlozenia datetime,
	@data_rezerwacji datetime,
	@nazwa_restauracji varchar(50),
	@id_firmy int,
	@id_pracownika int
AS
BEGIN
	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Rezerwacje_Firm_Im
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			BEGIN
				;THROW 52000, 'Nie ma takiej restauracji',1
			END
			DECLARE @id_restauracji int =(SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			IF NOT EXISTS(SELECT * FROM Rezerwacje WHERE @data_rezerwacji=Data_rezerwacji 
				AND Data_złożenia=@data_zlozenia AND ID_Restauracji=@id_restauracji)
			BEGIN
				INSERT INTO Rezerwacje(Data_złożenia,Data_rezerwacji,ID_Restauracji)
				VALUES (@data_zlozenia,@data_rezerwacji,@id_restauracji)
			END
			DECLARE @id_rezerwacji int=(SELECT ID_rezerwacji FROM Rezerwacje WHERE @data_rezerwacji=Data_rezerwacji 
				AND Data_złożenia=@data_zlozenia AND ID_Restauracji=@id_restauracji)
			DECLARE @miejsca_siedzace INT = (SELECT SUM(o.Liczba_miejsc) FROM dbo.Szczegóły_Rezerwacji sr
													INNER JOIN obostrzenia o ON o.ID_Obostrzenia=sr.ID_obostrzenia
													WHERE ID_rezerwacji=@id_rezerwacji)
			
			DECLARE @aktualnie_przypisani INT = (SELECT COUNT(*) FROM dbo.Rezerwacje_Firm_Imiennie WHERE ID_rezerwacji=@id_rezerwacji)
			
			IF @miejsca_siedzace>@aktualnie_przypisani
			BEGIN
				INSERT INTO Rezerwacje_Firm_Imiennie(ID_rezerwacji,ID_firmy,ID_pracownika)
				VALUES (@id_rezerwacji,@id_firmy,@id_pracownika)
			END
			ELSE
			BEGIN
				DECLARE @pobrane_obostrzenie int = dbo.Pobierz_Obostrzenie_Do_Rezerwacji(@id_restauracji,@data_rezerwacji)
				IF @pobrane_obostrzenie IS NULL
				BEGIN
					EXEC dbo.Anuluj_Rezerwacje @id_rezerwacji = @id_rezerwacji -- int
					;THROW 52000, 'Nie mozna dodac wiekszej ilosci osob. Brak wolnych miejsc w danym terminie',1
				END
				ELSE
				BEGIN
					INSERT INTO dbo.Szczegóły_Rezerwacji( ID_rezerwacji,ID_obostrzenia)
					VALUES(@id_rezerwacji,@pobrane_obostrzenie)
					INSERT INTO Rezerwacje_Firm_Imiennie(ID_rezerwacji,ID_firmy,ID_pracownika)
					VALUES (@id_rezerwacji,@id_firmy,@id_pracownika)
				END
			END
    	COMMIT TRAN Dodaj_Rezerwacje_Firm_Im
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Rezerwacje_Firm_Im
        	DECLARE @errorMsg nvarchar (2048) = 'Blad dodawania rezerwacji: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Rezerwacje_Ind]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Rezerwacje_Ind] 
	@data_zlozenia date,
	@data_rezerwacji date,
	@nazwa_restauracji varchar(50),
	@id_klienta int,
	@id_zamowienia int,
	@liczba_osob int
AS
BEGIN
	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Dodaj_Rezerwacje_Ind
			IF @liczba_osob<2
			BEGIN
				;THROW 52000, 'Rezerwacja musi byc dla min 2 osob',1
			END
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			BEGIN
				;THROW 52000, 'Nie ma takiej restauracji',1
			END
			DECLARE @id_restauracji int =(SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			IF NOT EXISTS (SELECT * FROM Zamówienia WHERE @id_zamowienia=ID_zamówienia)
			BEGIN
				;THROW 52000, 'Najpierw trzeba zlozyc zamowienie',1
			END
			DECLARE @wart_zam money=(SELECT SUM(Cena_jednostkowa*Ilość) FROM Szczegóły_Zamówień WHERE ID_zamówienia=@id_zamowienia)
			DECLARE @ilosc_zam int = (SELECT COUNT(*) FROM Zamówienia z
			INNER JOIN Obsluga o ON o.ID_pracownika = z.Pracownik_obsługujący
			INNER JOIN Restauracje r ON r.ID_restauracji=o.ID_Restauracji
			WHERE @id_klienta=ID_klienta AND @id_restauracji=r.ID_restauracji)-1 -- aby wykluczyc wlasnie zlozone
			IF @ilosc_zam<5 AND @wart_zam<200
			BEGIN
				;THROW 52000, 'Niespelniony warunek zamowienia',1
			END
			IF @ilosc_zam>=5 AND @wart_zam<50
			BEGIN
				;THROW 52000, 'Niespelniony warunek zamowienia',1
			END
			DECLARE @liczba_wolnych_miejsc int = dbo.Liczba_Wolnych_Miejsc(@id_restauracji,@data_rezerwacji)
			IF @liczba_wolnych_miejsc<@liczba_osob
			BEGIN
				;THROW 52000, 'Zbyt malo wolnych miejsc',1
			END
			INSERT INTO Rezerwacje(Data_złożenia,Data_rezerwacji,ID_Restauracji)
			VALUES (@data_zlozenia,@data_rezerwacji,@id_restauracji)
			DECLARE @id int=@@IDENTITY
			INSERT INTO Rezerwacje_Ind(ID_rezerwacji,ID_klienta,ID_zamówienia)
			VALUES (@id,@id_klienta,@id_zamowienia)
			DECLARE @liczba_usadzonych int = 0
			WHILE @liczba_usadzonych<@liczba_osob
			BEGIN
				DECLARE @potwierdzenie_stolika int = dbo.Pobierz_Obostrzenie_Do_Rezerwacji(@id_restauracji,@data_rezerwacji)
				DECLARE @zajete int = (SELECT Liczba_miejsc FROM Obostrzenia WHERE ID_Obostrzenia=@potwierdzenie_stolika)
				SET @liczba_usadzonych=@liczba_usadzonych+@zajete
				INSERT INTO Szczegóły_Rezerwacji(ID_rezerwacji,ID_obostrzenia)
				VALUES (@id,@potwierdzenie_stolika)
			END
    	COMMIT TRAN Dodaj_Rezerwacje_Ind
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Dodaj_Rezerwacje_Ind
        	DECLARE @errorMsg nvarchar (2048) = 'Blad dodawania rezerwacji: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Stolik]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Stolik]
	@max_liczba_miejsc int,
	@nazwa_lokalu varchar(50),
	@ulica varchar(50),
	@miasto varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @id_restauracji int = (
			SELECT r.ID_restauracji FROM Restauracje r
			INNER JOIN Miasta m on r.Miasto=m.ID_miasta
			WHERE @nazwa_lokalu=r.Nazwa
			AND @ulica=r.Ulica
			AND @miasto=m.Nazwa_miasta)
		INSERT INTO Stoliki(Max_liczba_miejsc,ID_Restauracji)
		VALUES (@max_liczba_miejsc,@id_restauracji)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania stolika: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Dodaj_Zamowienie]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Dodaj_Zamowienie] 
	@nazwa_restauracji varchar(50),
	@id_klienta int,
	@data_zamowienia datetime,
	@data_odbioru datetime =null,
	@na_wynos varchar(1),
	@id_pracownika int
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Dodaj_Zamowienie
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			BEGIN
				;THROW 52000, 'Nie ma takiej restauracji',1
			END
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			IF NOT EXISTS (SELECT * FROM Klienci WHERE @id_klienta=ID_klienta)
			BEGIN
				;THROW 52000, 'Nie ma takiego klienta',1
			END
			IF @data_odbioru is NULL AND @na_wynos='T'
			BEGIN
				;THROW 52000, 'Przy zamawianiu na wynos trzeba podac date odbioru',1
			END
			IF @data_odbioru is NULL
			BEGIN
				SET @data_odbioru=DATEADD(hh,1,@data_zamowienia)
			END
			IF NOT EXISTS (SELECT * FROM Obsluga WHERE ID_pracownika=@id_pracownika AND ID_Restauracji=@id_restauracji)
			BEGIN
				;THROW 52000, 'Zamowienie obsluguje nieuprawniona osoba',1
			END
			DELETE FROM Aktualnie_Przyznane_Rabaty WHERE @id_klienta=ID_klienta AND Data_wygaśnięcia IS NOT NULL AND Data_wygaśnięcia<GETDATE()
			DELETE FROM Aktualnie_Przyznane_Rabaty WHERE @id_klienta=ID_klienta AND ID_rabatu IN(
				SELECT ID_rabatu FROM Rabaty WHERE Data_zdjęcia IS NOT NULL)
			IF @id_klienta IN (SELECT ID_klienta FROM Klienci_Ind)
			BEGIN
				EXEC Aktualizuj_Rabat_Ind_Staly
					@id_klienta,
					@id_restauracji
				EXEC Aktualizuj_Rabat_Ind_Jednorazowy
					@id_klienta,
					@id_restauracji
			END
			ELSE
			BEGIN
				EXEC Aktualizuj_Rabat_Firm_Miesieczny
					@id_klienta,
					@id_restauracji
				EXEC Aktualizuj_Rabat_Firm_Kwartalny
					@id_klienta,
					@id_restauracji
			END
			INSERT INTO Zamówienia(ID_klienta,Data_zamówienia,Data_odbioru,Na_wynos,Pracownik_obsługujący)
			VALUES (@id_klienta,@data_zamowienia,@data_odbioru,@na_wynos,@id_pracownika)
			DECLARE iter CURSOR
			FOR 
				SELECT a.ID_rabatu
				FROM Aktualnie_Przyznane_Rabaty a
				INNER JOIN Rabaty r ON r.ID_rabatu=a.ID_rabatu
				WHERE @id_klienta=a.ID_klienta AND r.ID_Restauracji=@id_restauracji 
			DECLARE @rabat int
			OPEN iter
			FETCH NEXT FROM iter INTO @rabat
			WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE @data_wygasniecia date=(SELECT Data_wygaśnięcia FROM Aktualnie_Przyznane_Rabaty
				WHERE @rabat=ID_rabatu AND @id_klienta=ID_klienta)
				IF @data_wygasniecia<GETDATE()
				BEGIN
					EXEC Odbierz_Rabat_Klientowi
						@rabat,
						@id_klienta
				END
				FETCH NEXT FROM iter INTO @rabat
			END
			CLOSE iter
			DEALLOCATE iter
		COMMIT TRAN Dodaj_Zamowienie
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Dodaj_Zamowienie
		DECLARE @errorMsg nvarchar (2048) = 'Blad dodania zamowienia: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Odbierz_Dostawe]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Odbierz_Dostawe]
	@id_dostawy int,
	@nazwa_restauracji varchar(50),
	@data_dostawy date
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
    	BEGIN TRAN Odbierz_Dostawe
			IF NOT EXISTS (SELECT * FROM Dostawy WHERE @id_dostawy=ID_dostawy)
			BEGIN
				;THROW 52000, 'Nie istnieje taka dostawa',1
			END
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			BEGIN
				;THROW 52000, 'Nie istnieje taka restauracja',1
			END
			IF @data_dostawy<(SELECT Data_zamówienia FROM Dostawy WHERE @id_dostawy=ID_dostawy)
			BEGIN
				;THROW 52000, 'Data odbioru nie moze byc wczesniejsza niz zamowienia',1
			END
			UPDATE Dostawy SET Data_dostawy=@data_dostawy WHERE ID_dostawy=@id_dostawy
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE Nazwa=@nazwa_restauracji)
			DECLARE iter CURSOR
			FOR 
				SELECT ID_półproduktu
				FROM Szczegóły_Dostaw
				WHERE @id_dostawy=ID_dostawy
			DECLARE @id_polproduktu int
			OPEN iter
			FETCH NEXT FROM iter INTO @id_polproduktu
			WHILE @@FETCH_STATUS = 0
			BEGIN
				DECLARE @nazwa_polproduktu varchar(50)=(SELECT Nazwa FROM Polprodukty WHERE @id_polproduktu=ID_półproduktu)
				DECLARE @ilosc_jednostek float =(SELECT Ilość_jednostek FROM Szczegóły_Dostaw WHERE ID_dostawy=@id_dostawy
					AND @id_polproduktu=ID_półproduktu)
				EXEC Dodaj_Do_Magazynu
					@nazwa_restauracji,
					@nazwa_polproduktu,
					@ilosc_jednostek
				FETCH NEXT FROM iter INTO @id_polproduktu
			END
			CLOSE iter
			DEALLOCATE iter
			COMMIT TRAN Odbierz_Dostawe
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Odbierz_Dostawe
        	DECLARE @errorMsg nvarchar (2048) = 'Blad przy odbiorze dostawy: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Odbierz_Rabat_Klientowi]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Odbierz_Rabat_Klientowi]
	@id_rabatu int,
	@id_klienta int
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRAN Odbierz_Rabat
			IF NOT EXISTS (SELECT * FROM Rabaty WHERE ID_rabatu=@id_rabatu)
			BEGIN 
				;THROW 52000, 'Nie istnieje taki rabat',1
			END
			IF NOT EXISTS (SELECT * FROM Klienci WHERE ID_klienta=@id_klienta)
			BEGIN 
				;THROW 52000, 'Nie istnieje taki klient',1
			END
			DELETE FROM Aktualnie_Przyznane_Rabaty WHERE @id_rabatu=ID_rabatu
		COMMIT TRAN Odbierz_Rabat
	END TRY
	BEGIN CATCH
		ROLLBACK TRAN Odbierz_Rabat
		DECLARE @errorMsg nvarchar (2048) = 'Blad wygaszania rabatu: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Pobierz_Z_Magazynu]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Pobierz_Z_Magazynu]
   	@nazwa_restauracji varchar(50),
	@nazwa_produktu varchar(50),
	@ilosc_jednostek float 
AS
BEGIN
   	SET NOCOUNT ON;
   	BEGIN TRY
    	BEGIN TRAN Pobierz_Z_Magazynu
			IF NOT EXISTS (SELECT * FROM Polprodukty WHERE @nazwa_produktu=Nazwa)
			BEGIN
				;THROW 52000, 'Nie istnieje taki polprodukt',1
			END
			IF NOT EXISTS (SELECT * FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			BEGIN
				;THROW 52000, 'Nie istnieje taka restauracja',1
			END
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			DECLARE @id_produktu int = (SELECT ID_półproduktu FROM Polprodukty WHERE Nazwa=@nazwa_produktu)
			IF @ilosc_jednostek<=0
			BEGIN
				;THROW 52000, 'Liczba pobieranych jednostek musi byc wieksza od 0',1
			END
			IF NOT EXISTS(
				SELECT * FROM Stan_Magazynowy WHERE @id_restauracji=ID_restauracji
				AND @id_produktu=ID_półproduktu
			)
			BEGIN
				;THROW 52000, 'W magazynie nie odnotowano tego produktu do tej pory',1
			END
			IF @ilosc_jednostek>(SELECT Stan_magazynowy FROM Stan_Magazynowy WHERE @id_restauracji=ID_restauracji
				AND @id_produktu=ID_półproduktu)
			BEGIN
				;THROW 52000, 'Proba pobrania zbyt wielu jednostek',1
			END
			UPDATE Stan_Magazynowy SET Stan_magazynowy=Stan_magazynowy-@ilosc_jednostek
				WHERE ID_restauracji=@id_restauracji AND @id_produktu=ID_półproduktu
    	COMMIT TRAN Pobierz_Z_Magazynu
	END TRY
	BEGIN CATCH
        	ROLLBACK TRAN Pobierz_Z_Magazynu
        	DECLARE @errorMsg nvarchar (2048) = 'Blad pobierania polproduktu z magazynu: '+ ERROR_MESSAGE () ;
    	THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Przyznaj_Rabat_Klientowi]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Przyznaj_Rabat_Klientowi]
	@id_rabatu int,
	@id_klienta int,
	@data_przyznania date=null,
	@data_wygasniecia date=null
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM Rabaty WHERE ID_rabatu=@id_rabatu)
		BEGIN 
			;THROW 52000, 'Nie istnieje taki rabat',1
		END
		DECLARE @data_zdjecia date = (SELECT Data_zdjęcia FROM Rabaty WHERE @id_rabatu=ID_rabatu)
		IF NOT(@data_zdjecia is NULL OR @data_zdjecia>=GETDATE())
		BEGIN
			;THROW 52000, 'Ten rabat utracil waznosc',1
		END
		IF NOT EXISTS (SELECT * FROM Klienci WHERE ID_klienta=@id_klienta)
		BEGIN 
			;THROW 52000, 'Nie istnieje taki klient',1
		END
		IF EXISTS(SELECT * FROM Klienci_Biz WHERE @id_klienta=ID_klienta) AND
		(EXISTS (SELECT * FROM Rabaty_Ind_Jednorazowe WHERE ID_rabatu=@id_rabatu) OR
		EXISTS(SELECT * FROM Rabaty_Ind_Stale WHERE ID_rabatu=@id_rabatu))
		BEGIN
			;THROW 52000, 'Proba przyznania rabatu dla klienta indywidualnego firmie',1
		END
		IF EXISTS(SELECT * FROM Klienci_Ind WHERE @id_klienta=ID_klienta) AND
		NOT EXISTS (SELECT * FROM Rabaty_Ind_Jednorazowe WHERE ID_rabatu=@id_rabatu) AND
		NOT EXISTS(SELECT * FROM Rabaty_Ind_Stale WHERE ID_rabatu=@id_rabatu)
		BEGIN
			;THROW 52000, 'Proba przyznania rabatu dla firmy klientowi indywidualnemu',1
		END
		IF @data_przyznania is NULL
		BEGIN
			SET @data_przyznania=GETDATE()
		END
		IF EXISTS(SELECT * FROM Rabaty_Ind_Jednorazowe WHERE ID_rabatu=@id_rabatu)
		BEGIN
			DECLARE @waznosc int = (SELECT Waznosc FROM Rabaty_Ind_Jednorazowe WHERE ID_rabatu=@id_rabatu)
			SET @data_wygasniecia=DATEADD(dd,@waznosc,@data_przyznania)
		END
		INSERT INTO Aktualnie_Przyznane_Rabaty(ID_rabatu,ID_klienta,Data_przyznania,Data_wygaśnięcia)
		VALUES(@id_rabatu,@id_klienta,@data_przyznania,@data_wygasniecia)
	END TRY
	BEGIN CATCH
		DECLARE @errorMsg nvarchar (2048) = 'Blad przyznania rabatu: '+ ERROR_MESSAGE () ;
	    THROW 52000 , @errorMsg ,1;
	END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Usun_Polowe_Pozycji_Z_Menu]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Usun_Polowe_Pozycji_Z_Menu]
	@id_restauracji int,
	@data date
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Menu SET Data_zdjęcia=GETDATE() WHERE ID_pozycji IN(
		SELECT TOP 50 PERCENT a.ID_pozycji FROM dbo.Pokaz_Menu_Dnia(@id_restauracji,DATEADD(day,-1,@data)) a
		INNER JOIN dbo.Pokaz_Menu_Dnia(@id_restauracji,DATEADD(day,-14,@data)) b ON a.ID_pozycji = b.ID_pozycji
		ORDER BY a.Data_wprowadzenia ASC)
END
GO
/****** Object:  StoredProcedure [dbo].[Usun_Z_Menu]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Usun_Z_Menu]
	@nazwa_dania varchar(50),
	@nazwa_restauracji varchar(50),
	@data_zdjecia date
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
        BEGIN TRAN Usun_Z_Menu
			DECLARE @id_dania int = (SELECT ID_dania FROM Dania WHERE Nazwa_dania=@nazwa_dania)
			DECLARE @id_restauracji int = (SELECT ID_restauracji FROM Restauracje WHERE @nazwa_restauracji=Nazwa)
			IF NOT EXISTS (SELECT * FROM Menu WHERE @id_dania=ID_dania AND ID_restauracji=@id_restauracji AND Data_zdjęcia IS NULL)
			BEGIN
				;THROW 52000, 'Nie ma takiej pozycji obecnie w Menu dla tej restauracji',1
			END
			DECLARE @id_pozycji int = (SELECT ID_pozycji FROM Menu WHERE ID_restauracji=@id_restauracji 
										AND ID_dania=@id_dania AND Data_zdjęcia IS NULL)
			IF @data_zdjecia<GETDATE()
			BEGIN
				;THROW 52000, 'Data zdjecia nie moze byc chwila z przeszlosci',1
			END
			IF @data_zdjecia<(SELECT Data_wprowadzenia FROM Menu WHERE ID_restauracji=@id_restauracji 
										AND ID_dania=@id_dania AND Data_zdjęcia IS NULL)
			BEGIN
				;THROW 52000, 'Data zdjecia nie moze wczesniejsza niz dodania',1
			END
			UPDATE Menu
			SET Data_zdjęcia=@data_zdjecia

        COMMIT TRAN Usun_Z_Menu
    END TRY
    BEGIN CATCH
            ROLLBACK TRAN Usun_Z_Menu
            DECLARE @errorMsg nvarchar (2048) = 'Blad usuniecia z menu: '+ ERROR_MESSAGE () ;
        THROW 52000 , @errorMsg ,1;
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[Zamknij_Zamowienie]    Script Date: 2021-01-20 23:12:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Zamknij_Zamowienie]
	@id_zamowienia int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @id_klienta int =(SELECT ID_klienta FROM Zamówienia WHERE ID_zamówienia=@id_zamowienia)
	DECLARE @id_restauracji int =(SELECT o.ID_Restauracji FROM Obsluga o
	INNER JOIN Zamówienia z ON z.Pracownik_obsługujący=o.ID_pracownika WHERE z.ID_zamówienia=@id_zamowienia)
	DECLARE @id_rabatu int =(SELECT r.ID_rabatu FROM Rabaty r INNER JOIN Rabaty_Ind_Jednorazowe ri ON ri.ID_rabatu=r.ID_rabatu
	WHERE r.Data_zdjęcia is NULL AND r.ID_Restauracji=@id_restauracji)
	IF @id_rabatu IS NOT NULL
	BEGIN
		DELETE FROM Aktualnie_Przyznane_Rabaty WHERE ID_rabatu=@id_rabatu AND ID_klienta=@id_klienta
	END
END
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Dostawcy', @level2type=N'CONSTRAINT',@level2name=N'CK_Dostawcy_Ulica'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Restauracje"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stan_Magazynowy"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 148
               Right = 507
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Miasta"
            Begin Extent = 
               Top = 159
               Left = 390
               Bottom = 300
               Right = 584
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Polprodukty"
            Begin Extent = 
               Top = 7
               Left = 555
               Bottom = 126
               Right = 753
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Braki_W_Magazynie'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Braki_W_Magazynie'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Klienci"
            Begin Extent = 
               Top = 57
               Left = 118
               Bottom = 198
               Right = 345
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Szczegóły_Zamówień"
            Begin Extent = 
               Top = 34
               Left = 806
               Bottom = 197
               Right = 1024
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Zamówienia"
            Begin Extent = 
               Top = 34
               Left = 465
               Bottom = 197
               Right = 712
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Klienci_Wydatki'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Klienci_Wydatki'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1[60] 2[22] 3) )"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2[66] 3) )"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4[60] 2) )"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2) )"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Menu"
            Begin Extent = 
               Top = 7
               Left = 532
               Bottom = 170
               Right = 762
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Dania"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 170
               Right = 484
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Szczegóły_Zamówień"
            Begin Extent = 
               Top = 7
               Left = 810
               Bottom = 170
               Right = 1028
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Najpopularniejsze_Dania'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Najpopularniejsze_Dania'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Dania"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 208
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Kategorie"
            Begin Extent = 
               Top = 6
               Left = 246
               Bottom = 102
               Right = 421
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Owoce_Morza'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Owoce_Morza'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Dania"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Menu"
            Begin Extent = 
               Top = 7
               Left = 290
               Bottom = 170
               Right = 520
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Polprodukty"
            Begin Extent = 
               Top = 7
               Left = 568
               Bottom = 126
               Right = 766
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Przepisy"
            Begin Extent = 
               Top = 7
               Left = 814
               Bottom = 148
               Right = 1012
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Restauracje"
            Begin Extent = 
               Top = 7
               Left = 1060
               Bottom = 170
               Right = 1254
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Stan_Magazynowy"
            Begin Extent = 
               Top = 126
               Left = 568
               Bottom = 267
               Right = 785
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Pozycje_Niemozliwe_Do_Stworzenia'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Pozycje_Niemozliwe_Do_Stworzenia'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Pozycje_Niemozliwe_Do_Stworzenia'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Klienci_Biz"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 242
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Klienci_Ind"
            Begin Extent = 
               Top = 150
               Left = 291
               Bottom = 291
               Right = 485
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Pracownicy_Firm"
            Begin Extent = 
               Top = 7
               Left = 552
               Bottom = 126
               Right = 746
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1176
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1356
         SortOrder = 1416
         GroupBy = 1350
         Filter = 1356
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Pracownicy_Firm'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Pracownicy_Firm'
GO
USE [master]
GO
ALTER DATABASE [u_boron] SET  READ_WRITE 
GO
