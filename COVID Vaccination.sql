--This project show my ability to use SQL for data exploration
--Data about COVID per day downloaded from https://ourworldindata.org/covid-vaccinations
--I splitted the dataset into 2 Excel File (contains data of deaths and vaccinated peoples) just to demonstrate JOIN in the query

--Checking imported xlsx file
SELECT *
FROM [Portfolio Project]..covid_death
ORDER BY 3,4

--SELECT *
--FROM [Portfolio Project]..covid_vacc
--ORDER BY 3,4

--SELECT data that will be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM [Portfolio Project]..covid_death
order by 1,2

--Total Cases vs Total Death in Indonesia
SELECT Location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as percent_population_infected
From [Portfolio Project]..covid_death
WHERE Location = 'Indonesia'
ORDER BY 1,2;

--Rank of Countries with highest infection rate compared to population
SELECT Location,Population,MAX(total_cases) as total_cases, (MAX(total_cases/population))*100 as percent_population_infected
FROM [Portfolio Project]..covid_death
GROUP BY Location, Population
ORDER BY percent_population_infected desc

--Rank of Countries with highest death count
SELECT Location,MAX(CAST(total_deaths as bigint)) as total_deaths
From [Portfolio Project]..covid_death
WHERE continent is NOT NULL
GROUP BY Location
ORDER BY total_deaths desc

--World Death Percentage per each day
SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as bigint)) as total_deaths, (SUM(CAST(new_deaths as bigint))/SUM(New_Cases)) as Death_Percentage
FROM [Portfolio Project]..covid_death
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccination (July 2022)
--JOIN  2 tables
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM [Portfolio Project]..covid_death dea
JOIN [Portfolio Project]..covid_vacc vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2

--Total Population vs Vaccination (July 2022)
--By using CTE to calculate the percentage of vaccination in the next query
With vaccinated (Continent, Location, Date, Population, New_Vaccinations, total_vaccination)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) as total_vaccination
FROM [Portfolio Project]..covid_death dea
JOIN [Portfolio Project]..covid_vacc vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (total_vaccination/Population)
FROM vaccinated
ORDER BY 2,3

-- Using Temp Table to perform Calculation on Partition By in previous query
DROP Table if exists #percent_pop_vaccinated
Create Table #percent_pop_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
total_vaccination numeric
)

Insert into #percent_pop_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as total_vaccination
From [Portfolio Project]..covid_death dea
Join [Portfolio Project]..covid_vacc vac
	On dea.location = vac.location
	and dea.date = vac.date

SELECT*, (total_vaccination/Population)*100
FROM #percent_pop_vaccinated
ORDER BY 2,3

--Create View for Visualization
CREATE VIEW percent_peoples_vaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as total_vaccination
FROM [Portfolio Project]..covid_death dea
JOIN [Portfolio Project]..covid_vacc vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
FROM percent_peoples_vaccinated
