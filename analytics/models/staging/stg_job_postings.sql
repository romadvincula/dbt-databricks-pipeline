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