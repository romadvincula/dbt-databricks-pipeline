{% set extension_keywords = [
    "No degree mentioned", 
    "Dental insurance", 
    "Paid time off", 
    "Health insurance"
    ]
-%}


with source as (
    select 
        * 
    
    from {{ source('jobs', 'raw_job_postings')}}
    where error is not true
)

, parsed as (
    select
        *,
        FROM_JSON(job_extensions_raw, 'array<string>') as job_extensions
    
    from source
)

, cleaned as (
    select
        job_id,
        job_title,
        TRIM(company_name) as company_name,
        job_location,
        REGEXP_REPLACE(job_via, '^via ', '') as source_platform,
        job_posted_at,
        job_salary,
        -- lower bound: the number before the en-dash, times its K or M suffix
        {{ parse_salary('min') }} AS salary_min,
        -- upper bound: the same parse on the LAST segment, so a single value is its own range
        {{ parse_salary('max') }} AS salary_max,
        -- avg of min and max salary
        ({{ parse_salary('min') }} + {{ parse_salary('max') }}) / 2 AS salary_avg,
        -- pay period, read off the end of the text: 'a year', 'an hour'
        NULLIF(REGEXP_EXTRACT(job_salary, 'an? (year|hour|month|day|week)$', 1), '') AS salary_period,
        -- currency marker; a salaried row with no marker is stamped USD on purpose
        CASE
            WHEN job_salary IS NOT NULL
            THEN COALESCE(NULLIF(TRIM(REGEXP_EXTRACT(job_salary, '^([^0-9]+)', 1)), ''), 'USD')
        END AS salary_currency,
        job_schedule_type,
        job_work_from_home,
        search_time AS searched_at,
        search_date,
        search_term,
        search_location,
        {% for keyword in extension_keywords -%}
        ARRAY_CONTAINS(
            job_extensions,
            "{{keyword}}"
        ) AS has_{{keyword | lower | replace(' ', '_')}}
        {{- "," if not loop.last }}
        {% endfor -%}

    from parsed
)

select * from cleaned