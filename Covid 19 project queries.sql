SELECT * 
FROM project.coviddeaths
order by 3, 4

#SELECT * 
#FROM project.Covidvaccinations
#order by 3, 4

-- Select data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
From project.coviddeaths
order by 1, 2

-- Total cases vs Total death
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From project.coviddeaths
Where location like '%India%'
and continent is not null
order by 1, 2


-- Total cases vs  Population
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
From project.coviddeaths
Where location like '%India%'
and continent is not null
order by 1, 2

-- Countries with highest infection rate compared to population
SELECT Location, population, Max(total_cases) as HighestinfectionCount, Max((total_cases/population))*100 AS PercentPopulationInfected
From project.coviddeaths
Where location like '%india%'
Group by Location, population
order by PercentPopulationInfected desc



-- Countries with highest death count per population
SELECT Location, Max(cast(total_deaths as UNSIGNED)) as TotaldeathCount
From project.coviddeaths
#Where location like '%states%'
Group by Location
order by TotaldeathCount desc



-- Continent with the highest death count per population
SELECT Continent, Max(cast(total_deaths as UNSIGNED)) as TotaldeathCount
From project.coviddeaths
Where location like '%india%'
Where continent is not null
Group by Continent
order by TotaldeathCount desc


-- Global Numbers
SELECT sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 AS DeathPercentage
From project.coviddeaths
-- Where location like '%india%'
where continent is not null
-- Group by date
order by 1, 2


-- Total Population vs vaccinations
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum(convert(vac.new_vaccinations, unsigned)) over (partition by dea.location order by dea.location, 
dea.date) as RollingPeoplevaccinated
-- , (RollingPeoplevaccinated/population)*100
From project.coviddeaths dea
join project.covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where dea.continent is not null
order by 2, 3


-- Use CTE

With PopVsVac (Continent, location, date, population, new_vaccinations, RollingPeoplevaccinated)
as
(
Select
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, sum(convert(vac.new_vaccinations, unsigned)) over (partition by dea.location order by dea.location, 
	dea.date) as RollingPeoplevaccinated
	-- , (RollingPeoplevaccinated/population)*100
From 
	project.coviddeaths dea
join 
	project.covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
where 
	dea.continent is not null
)
Select *, (RollingPeoplevaccinated/Population)*100
From PopvsVac


-- Temp Table
Create Temporary Table PercentPopulationVaccinated 
(
continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
;With CTE as (
	Select
		dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
		, sum(convert(vac.new_vaccinations, unsigned)) over (partition by dea.location order by dea.location, 
		dea.date) as RollingPeoplevaccinated
	From 
		project.coviddeaths dea
	join 
		project.covidvaccinations vac
	on dea.location = vac.location
    and dea.date = vac.date
	-- where dea.continent is not null
)

Select *, (RollingPeoplevaccinated/Population)*100
From CTE


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(vac.new_vaccinations, unsigned)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population)*100
From project.coviddeaths dea
Join project.covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
