select *
from PortfolioProject..CovidDeaths
Where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null
order by 1,2

--Looking at Total Cases vs Total Deaths

SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CAST(total_cases AS float) <> 0 
        THEN TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float) 
        ELSE NULL 
    END AS death_rate
FROM
    PortfolioProject..CovidDeaths
ORDER BY 1, 2;

SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CAST(total_cases AS float) <> 0 
        THEN CONCAT(ROUND((TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float)) * 100, 2), '%')
        ELSE NULL 
    END AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths 
	Where continent is not null
ORDER BY 1, 2;
--Looking at Total Cases Vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CAST(total_cases AS float) <> 0 
        THEN CONCAT(ROUND((TRY_CAST(total_deaths AS float) / TRY_CAST(total_cases AS float)) * 100, 2), '%')
        ELSE NULL 
    END AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
	Where Location like '%nigeria%' 
ORDER BY 1, 2;

--Looking at Total Cases Vs Population
--Show what percentage of the population got covid
SELECT
    Location,
    date,
	population,
    total_cases, 
    CASE 
        WHEN TRY_CAST (total_cases AS float) <> 0 AND TRY_CAST(population AS float) <> 0
        THEN CONCAT(ROUND((TRY_CAST(total_cases AS float) / TRY_CAST(population AS float)) * 100, 2), '%')
        ELSE NULL 
    END AS PercentPopulationInfected
FROM
    PortfolioProject..CovidDeaths
 
ORDER BY 1, 2;

--Looking at Countries with Highest Infection Rate Compared to Population

SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((CAST(total_cases AS float) / NULLIF(CAST(Population AS float), 0))) * 100 AS PercentPopulationInfected
FROM
    PortfolioProject..CovidDeaths
GROUP BY
    Location, Population 
ORDER BY
    HighestInfectionCount DESC;

--Showing Countries With the Highest Death Count per Population
SELECT
    Location,
    MAX(total_deaths) AS TotalDeathCount
FROM
    PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
Where continent is not null
GROUP BY
    Location
ORDER BY
    TotalDeathCount DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT


-- Showing continents with the highest death count per population

SELECT
    continent,
    MAX(total_deaths) AS TotalDeathCount
FROM
    PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY
    continent
ORDER BY
    TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT
    date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) <> 0 
        THEN ROUND(SUM(CAST(new_deaths AS float)) / NULLIF(SUM(new_cases), 0) * 100, 2)
        ELSE NULL 
    END AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY
    date
ORDER BY
    date;

	--Total cases vs Total deaths

	SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS int)) AS total_deaths,
    CASE 
        WHEN SUM(new_cases) <> 0 
        THEN ROUND(SUM(CAST(new_deaths AS float)) / NULLIF(SUM(new_cases), 0) * 100, 2)
        ELSE NULL 
    END AS DeathPercentage
FROM
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 


--Looking at Total Population vs Vaccinations


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3 


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as PeopleVaccianted
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as PeopleVaccinated
--, (PeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
On dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 1,2,3 

--USE CTE
WITH PopVsVac (Continent, Location, Date, Population, new_vaccinations, PeopleVaccinated)
AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS PeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)
SELECT 
    *,
    (PeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM 
    PopVsVac;


-- Create the temporary table
-- Drop the temporary table if it already exists
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

-- Create the temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    PeopleVaccinated numeric
);
  -- Added this column for the cumulative sum
);

-- Insert data into the temporary table
Insert into #PercentPopulationVaccinated
Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PeopleVaccinated
From 
    PortfolioProject..CovidDeaths dea
    Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
where 
    dea.continent is not null;

-- Calculate the PercentageVaccinated
SELECT 
    *,
    (PeopleVaccinated / Population) * 100 AS PercentageVaccinated
FROM 
    #PercentPopulationVaccinated

--- creating view to store data for later visualizations

Create View PercentPopulationVaccinated as
Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(numeric, vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as PeopleVaccinated
From 
    PortfolioProject..CovidDeaths dea
    Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
where 
    dea.continent is not null;
--Order by 2,3

Select *
From PercentPopulationVaccinated 