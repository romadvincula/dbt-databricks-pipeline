{% set roles = dbt_utils.get_column_values(table=ref('stg_job_postings'), column='search_term') -%}

{% for role in roles -%}
SELECT
    search_term,
    count(*)
FROM {{ ref('stg_job_postings') }}
WHERE search_term = '{{ role }}'
GROUP BY search_term
{{ "UNION ALL" if not loop.last }}
{% endfor %}
{#-
{% set temp = dbt_utils.get_column_values(table=ref('stg_job_postings'), column='search_term') %}

{{ temp }}
-#}