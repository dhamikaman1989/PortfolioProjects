/*  
    COVID-19 Data Exploration
    Source : https://ourworldindata.org/covid-deaths
*/

-- Table 1 (CovidDeaths : Data Imported to SQL Developer)
SELECT COUNT(*) FROM COVIDDEATHS
                WHERE CONTINENT IS NOT NULL;                

SELECT * FROM COVIDDEATHS 
            WHERE CONTINENT IS NOT NULL
            ORDER BY 3,4;

-- Table 2 (Vaccinations:  Data Imported to SQL Developer)
SELECT * FROM COVIDVACCINATIONS 
                WHERE CONTINENT IS NOT NULL
                ORDER BY 3,4;


-- Selecting COVID data from Table 1(CovidDeaths).
SELECT 
               Location
               ,Date_report
               ,total_cases
               ,new_cases
               ,total_deaths
               ,population
                    FROM COVIDDEATHS 
                    WHERE CONTINENT IS NOT NULL
                    ORDER BY 1,2;

--  Lets look at Total Cases vs Total Deaths (United States)

SELECT 
               Location
               ,Date_report
               ,total_cases
               ,COALESCE(total_deaths,0) AS total_dealths    -- Don't want to show NULL value
               , COALESCE((total_deaths/total_cases)*100,0)  AS  DeathPercentage
                    FROM COVIDDEATHS 
                    WHERE location LIKE '%States%'
                                AND CONTINENT IS NOT NULL
                    ORDER BY 1,2;


--  Lets look at Total Cases vs Population for USA
--  What percentage of population (USA) got Covid

SELECT 
               Location
               ,Date_report
               ,total_cases
               ,Population
              , COALESCE((total_cases/Population)*100,0)  AS  CovidPercentage
                    FROM COVIDDEATHS 
                    WHERE location LIKE '%States%'
                                AND CONTINENT IS NOT NULL
                    ORDER BY 1,2;

--- Countries with highest COVID-19 infection rate compared to population

SELECT 
               Location
               ,Population
               ,MAX(total_cases) as HighestInfectionCount
               ,MAX((total_cases/Population)*100) AS PercentPopulationInfected
                    FROM COVIDDEATHS 
                    WHERE CONTINENT IS NOT NULL
                    GROUP BY Location,Population
                    ORDER BY PercentPopulationInfected DESC 
                    NULLS LAST;


--- Countries with highest COVID-19 Dealth Count per population


SELECT 
               Location
               ,MAX(total_deaths) as HighestDeathCount
               FROM COVIDDEATHS 
                WHERE CONTINENT IS NOT NULL 
                    GROUP BY Location
                    ORDER BY HighestDeathCount DESC 
                    NULLS LAST;


--- Showing Continents with highest COVID-19 Dealth Count per population

SELECT 
               Continent
               ,MAX(total_deaths) as HighestDeathCount
               FROM COVIDDEATHS 
                WHERE CONTINENT IS NOT NULL 
                    GROUP BY Continent
                    ORDER BY HighestDeathCount DESC ;
                    
-- Checking global counts per date

Select
            date_report
            ,SUM(new_cases) as total_cases
            ,SUM(new_deaths) as total_deaths
            ,SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
             FROM 
                    CovidDeaths
            WHERE Continent IS NOT NULL
            GROUP BY date_report
            ORDER BY 1;

-- Lets check the total world data (removed GROUP BY clause)

Select
            SUM(new_cases) as total_cases
            ,SUM(new_deaths) as total_deaths
            ,SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
             FROM 
                    CovidDeaths
            WHERE Continent IS NOT NULL;
            -- AND date_report < '30-APR-21'
            

--- Now, lets explore other table (CovidVaccinations)

-- Total Population vs Vaccinations

SELECT 
                death.continent
                ,death.location
                ,death.date_report
                ,death.population
                ,vac.new_vaccinations
               , SUM(vac.new_vaccinations) 
                  OVER (PARTITION BY death.location ORDER BY death.date_report) AS RollingPeopleVaccinated     
                FROM CovidDeaths death
                            Join CovidVaccinations vac
                    On death.date_report = vac.date_report
                            AND death.location = vac.location
                    WHERE death.continent IS NOT NULL
                     ---       AND death.location = 'India'
                    ORDER BY 2,3;


-- Using CTE to perform calculation done in the previous query

WITH PopVsVacc AS
(
SELECT 
                death.continent
                ,death.location
                ,death.date_report
                ,death.population
                ,vac.new_vaccinations
               , SUM(vac.new_vaccinations) 
                  OVER (PARTITION BY death.location ORDER BY death.location,
                                death.date_report) AS RollingPeopleVaccinated     
                FROM CovidDeaths death
                            Join CovidVaccinations vac
                    On death.date_report = vac.date_report
                            AND death.location = vac.location
                    WHERE death.continent IS NOT NULL
                     ---       AND death.location = 'India'
                    ORDER BY 2,3
)

SELECT 
                continent
                ,location
                ,date_report
                ,population
                ,new_vaccinations
                ,RollingPeopleVaccinated                
                ,(RollingPeopleVaccinated/Population)*100 AS PercentPeopleVaccinated
                FROM 
                    PopVsVacc;

--- Temporary tables

CREATE TABLE PercentPopulationVaccinated
(
    Continent VARCHAR(255)
    ,Location VARCHAR(255)
    ,Date_recorded DATE
    ,Population NUMBER
    ,New_Vaccinations NUMBER
    ,RollingPeopleVaccinated NUMBER
);

INSERT INTO PercentPopulationVaccinated
SELECT 
                death.continent
                ,death.location
                ,death.date_report
                ,death.population
                ,vac.new_vaccinations
               , SUM(vac.new_vaccinations) 
                  OVER (PARTITION BY death.location ORDER BY death.location,
                                death.date_report) AS RollingPeopleVaccinated     
                FROM CovidDeaths death
                            Join CovidVaccinations vac
                    On death.date_report = vac.date_report
                            AND death.location = vac.location
                    WHERE death.continent IS NOT NULL
                     ;

-- Select records from Temp table

SELECT *
                FROM PercentPopulationVaccinated;


--- Queries for Tableau dashboards.

--- 1
Select
            SUM(new_cases) as total_cases
            ,SUM(new_deaths) as total_deaths
            ,SUM(new_deaths)/SUM(New_Cases)*100 as DeathPercentage
             FROM 
                    CovidDeaths
            WHERE Continent IS NOT NULL;
            
--- 2

Select location, SUM(new_deaths) as TotalDeathCount
                From CovidDeaths
                Where continent is null 
            and location not LIKE '%income%'  AND   --- some weird location
                    location NOT IN ('World', 'European Union', 'International')
                Group by location
                order by TotalDeathCount desc;

-- 3

Select Location, 
                    COALESCE(Population,0) Population, 
                    COALESCE(MAX(total_cases),0) as HighestInfectionCount, 
                    COALESCE(Max((total_cases/population))*100,0) as PercentPopulationInfected
                        From CovidDeaths
                    GROUP BY Location, Population
                    order by PercentPopulationInfected desc;

-- 4

Select Location
            ,COALESCE(Population,0) Population,
            date_report, 
            COALESCE(MAX(total_cases),0) as HighestInfectionCount,  
            COALESCE(Max((total_cases/population))*100,0) as PercentPopulationInfected
                    From CovidDeaths
            Group by Location, Population, date_report
            order by PercentPopulationInfected desc;
            
--- 5







                

