# Tab `Personal` — Recursos Humanos `RetailMax`

Dashboard de Metabase · Área: Recursos Humanos 
Enfoque del tab: estructura, dotación y ciclo de vida del personal en tienda.

---

## 1 — Personal activo total

### 1. Nombre del indicador

Personal activo total

### 2. Qué representa en términos de negocio

Cantidad de colaboradores con contrato vigente (`activo = true`) que conforman la fuerza laboral disponible para operar tiendas en este momento.

### 3. Por qué es importante para el área

Es la métrica base de planificación de turnos, cobertura en piso de venta y presupuesto de nómina. Sin un headcount confiable no se puede dimensionar reclutamiento ni redistribución entre sucursales.

### 4. Visualización

**Numerica:** un solo valor responde de inmediato la pregunta `¿cuánta gente tenemos hoy?` sin ruido visual.

### 5. Consulta SQL

```sql
SELECT COUNT(*) AS personal_activo
FROM empleado
WHERE activo = TRUE;
```

---

## 2 — Dotación activa por tienda

### 1. Nombre del indicador

Dotación activa por tienda

### 2. Qué representa en términos de negocio

Distribución del personal activo en cada sucursal RetailMax, mostrando qué tiendas están más o menos dotadas respecto al resto de la red.

### 3. Por qué es importante para el área

Permite detectar desbalances (tiendas sobrecargadas o con déficit), apoyar traslados internos y priorizar contrataciones donde la operación lo exige.

### 4. Visualización

**Bar chart** — comparar 8 tiendas en un mismo eje facilita priorizar acciones por sucursal.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    COUNT(*) AS empleados_activos
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
WHERE e.activo = TRUE
GROUP BY t.id_tienda, t.nombre
ORDER BY empleados_activos DESC, t.nombre;
```

**Metabase:** 

- Eje X = `tienda`
- Eje Y = `empleados_activos`.

---

## 3 — Estructura de personal por puesto

### 1. Nombre del indicador

Estructura de personal por puesto

### 2. Qué representa en términos de negocio

Composición de la plantilla activa según rol operativo (Vendedor, Cajero, Supervisor, Gerente de Tienda, Bodeguero, Asesor de Ventas).

### 3. Por qué es importante para el área

Valida si la mezcla de cargos coincide con el modelo operativo de retail (más fuerza en ventas/caja vs. liderazgo y bodega) y orienta planes de capacitación o promoción interna.

### 4. Visualización

**Pie chart** o **barras**: el pie enfatiza proporciones de la estructura, y las barras ordenan mejor cuando hay muchas categorías similares en tamaño.

### 5. Consulta SQL

```sql
SELECT
    puesto,
    COUNT(*) AS cantidad
FROM empleado
WHERE activo = TRUE
GROUP BY puesto
ORDER BY cantidad DESC, puesto;
```

**Metabase:** 
Dimensión = `puesto`
Métrica = `cantidad`.

---

## 4 — Porcentaje de personal inactivo

### 1. Nombre del indicador

Porcentaje de personal inactivo

### 2. Qué representa en términos de negocio

Proporción de registros de empleado marcados como inactivos sobre el total histórico en la base (bajas, retiros o suspensiones registradas en el sistema).

### 3. Por qué es importante para el área

Un porcentaje elevado puede indicar rotación alta, problemas de retención o registros desactualizados; RH lo usa para activar planes de retención y limpieza de maestro de empleados.

### 4. Visualización

**Número (Scalar)** con formato de porcentaje, o **medidor (Gauge)** si Metabase lo ofrece en tu versión. Comunica un único KPI de salud de la plantilla.

### 5. Consulta SQL

```sql
SELECT ROUND(
    100.0 * SUM(CASE WHEN activo = FALSE THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
    1
) AS pct_personal_inactivo
FROM empleado;
```

---

## 5 — Antigüedad promedio del personal activo

### 1. Nombre del indicador

Antigüedad promedio del personal activo (años)

### 2. Qué representa en términos de negocio

Tiempo promedio, en años, que llevan en la empresa los colaboradores activos, calculado desde su `fecha_contratacion` hasta la fecha actual.

### 3. Por qué es importante para el área

Antiguedad baja sugiere plantilla nueva (mayor necesidad de inducción), antigüedad alta favorece estabilidad pero puede implicar riesgo de obsolescencia de habilidades si no hay desarrollo continuo.

### 4. Visualización

**Número (Scalar)**: un decimal en años es fácil de interpretar en reuniones de gestión de talento.

### 5. Consulta SQL

```sql
SELECT ROUND(
    AVG((CURRENT_DATE - fecha_contratacion) / 365.25)::numeric,
    1
) AS antiguedad_promedio_anios
FROM empleado
WHERE activo = TRUE;
```

---

## 6 — Contrataciones por mes (últimos 12 meses)

### 1. Nombre del indicador

Contrataciones por mes (últimos 12 meses)

### 2. Qué representa en términos de negocio

Volumen de altas nuevas agrupado por mes calendario, limitado a contrataciones en los últimos 12 meses respecto a la fecha de consulta.

### 3. Por qué es importante para el área

Muestra picos de reclutamiento, estacionalidad de ingresos y si las campañas de expansión o reapertura de tiendas se reflejan en contrataciones recientes.

### 4. Visualización

**Línea (Line chart)** o **barras temporales**: la serie en el tiempo revela tendencia y meses atípicos mejor que un solo número.

### 5. Consulta SQL

```sql
SELECT
    DATE_TRUNC('month', fecha_contratacion)::date AS mes,
    COUNT(*) AS contrataciones
FROM empleado
WHERE fecha_contratacion >= (CURRENT_DATE - INTERVAL '12 months')
GROUP BY DATE_TRUNC('month', fecha_contratacion)
ORDER BY mes;
```

**Metabase:** 

- Eje X = `mes` (como fecha) 
- Eje Y = `contrataciones`

---

## 7 — Salario promedio por puesto (activos)

### 1. Nombre del indicador

Salario promedio por puesto (personal activo)

### 2. Qué representa en términos de negocio

Remuneración media mensual (quetzales en los datos del lab) por tipo de puesto, solo para empleados activos.

### 3. Por qué es importante para el área

Apoya benchmarking interno, equidad salarial y revisión de bandas por rol antes de ajustes o negociaciones.

### 4. Visualización

**Bar chart**: comparar puestos con magnitudes distintas (p. ej. Gerente vs. Cajero) es más claro en barras que en un número único.

### 5. Consulta SQL

```sql
SELECT
    puesto,
    ROUND(AVG(salario), 2) AS salario_promedio
FROM empleado
WHERE activo = TRUE
GROUP BY puesto
ORDER BY salario_promedio DESC, puesto;
```

**Metabase:** 

- Eje X = `puesto`
- Eje Y = `salario_promedio`.

---

## Resumen


| #   | Indicador                         | Tipo de visualización |
| --- | --------------------------------- | --------------------- |
| 1   | Personal activo total             | Número                |
| 2   | Dotación activa por tienda        | Barras                |
| 3   | Estructura por puesto             | Pie o barras          |
| 4   | % personal inactivo               | Número / gauge        |
| 5   | Antigüedad promedio (años)        | Número                |
| 6   | Contrataciones por mes (12 meses) | Línea                 |
| 7   | Salario promedio por puesto       | Barras (opcional)     |


**Tab del dashboard:** `Personal`  
**Base de datos en Metabase:** `RetailMax`