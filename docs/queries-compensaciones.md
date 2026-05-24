# Tab `Compensaciones` — Recursos Humanos `RetailMax`

Dashboard de Metabase · Área: Recursos Humanos  
Enfoque del tab: eficiencia del gasto en personal, productividad por empleado, estructura salarial y retorno sobre la inversión en compensaciones.

---

## 1 — Costo total de nómina mensual (activos)

### 1. Nombre del indicador

Costo total de nómina mensual (personal activo)

### 2. Qué representa en términos de negocio

Suma de los salarios mensuales de todos los colaboradores activos; representa el compromiso financiero recurrente mínimo de la empresa en materia de personal.

### 3. Por qué es importante para el área

Es el insumo principal para la elaboración y control del presupuesto de RH. Cualquier decisión de contratación, ajuste o reorganización impacta directamente este número.

### 4. Visualización

**Número (Scalar):** un único valor monetario responde de inmediato la pregunta `¿cuánto pagamos de nómina este mes?` sin ambigüedad.

### 5. Consulta SQL

```sql
SELECT
    ROUND(SUM(salario), 2) AS nomina_mensual_total
FROM empleado
WHERE activo = TRUE;
```

---

## 2 — Ratio nómina / ingresos por tienda (eficiencia salarial)

### 1. Nombre del indicador

Ratio costo de nómina sobre ingresos brutos por tienda

### 2. Qué representa en términos de negocio

Por cada quetzal de ingreso que genera una tienda, cuántos centavos se destinan a pagar salarios del personal de esa sucursal. Un ratio de 0.15 significa que el 15 % de los ingresos se va en nómina.

### 3. Por qué es importante para el área

Es el indicador más directo de eficiencia del gasto en personal. Tiendas con ratio alto están absorbiendo demasiada nómina respecto a lo que venden; tiendas con ratio bajo podrían estar sub-dotadas. Permite priorizar auditorías de plantilla y negociar presupuestos con dirección financiera con datos concretos.

### 4. Visualización

**Bar chart horizontal ordenado de mayor a menor ratio:** expone de un vistazo qué tiendas son más y menos eficientes en el uso de su nómina.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    ROUND(SUM(e.salario), 2) AS nomina_mensual,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_brutos,
    ROUND(
        SUM(e.salario) /
        NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 0),
        4
    ) AS ratio_nomina_ingresos
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
INNER JOIN pedido p ON p.id_tienda = t.id_tienda
    AND p.estado = 'completado'
INNER JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE e.activo = TRUE
GROUP BY t.id_tienda, t.nombre
ORDER BY ratio_nomina_ingresos DESC;
```

**Metabase:**
- Eje X = `ratio_nomina_ingresos`
- Eje Y = `tienda`

---

## 3 — Ingresos generados por empleado (productividad individual)

### 1. Nombre del indicador

Top 15 empleados por ingresos generados en pedidos completados

### 2. Qué representa en términos de negocio

Suma de ventas (neta de descuentos) de los pedidos que cada empleado atendió, limitado a pedidos completados. Refleja la productividad comercial individual de la fuerza de ventas.

### 3. Por qué es importante para el área

Permite identificar a los empleados de mayor rendimiento para programas de reconocimiento, bonificaciones por desempeño o mentorías internas. También detecta empleados con volumen muy bajo que podrían requerir capacitación o reasignación.

### 4. Visualización

**Bar chart (top 15):** comparar empleados en un ranking de barras descendente es intuitivo y accionable; mostrar todos sería ilegible.

### 5. Consulta SQL

```sql
SELECT
    e.nombre AS empleado,
    e.puesto,
    t.nombre AS tienda,
    ROUND(
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2
    ) AS ingresos_generados
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
INNER JOIN pedido p ON p.id_empleado = e.id_empleado
    AND p.estado = 'completado'
INNER JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE e.activo = TRUE
GROUP BY e.id_empleado, e.nombre, e.puesto, t.nombre
ORDER BY ingresos_generados DESC
LIMIT 15;
```

**Metabase:**
- Eje X = `ingresos_generados`
- Eje Y = `empleado`

---

## 4 — ROI de compensación por empleado (ingresos / salario)

### 1. Nombre del indicador

Retorno sobre inversión salarial por empleado (ratio ingresos / salario)

### 2. Qué representa en términos de negocio

Cuántos quetzales de ingreso genera un empleado por cada quetzal que se le paga de salario mensual. Un ROI de 20 significa que el empleado genera 20 veces su salario en ventas.

### 3. Por qué es importante para el área

Es la métrica más completa para justificar o cuestionar una compensación: no basta con saber que alguien vende mucho si su salario también es desproporcionado, ni es justo penalizar a alguien por salario alto si su productividad lo respalda. Apoya decisiones de ajuste salarial, promociones y estructura de bonos.

### 4. Visualización

**Scatter plot (dispersión):** el eje X = salario, eje Y = ingresos generados. Cada punto es un empleado. Permite ver 4 cuadrantes naturales: alto salario / alta producción (estrellas), bajo salario / alta producción (candidatos a aumento), alto salario / baja producción (riesgo), bajo salario / baja producción (a revisar). Si Metabase no soporta scatter fácilmente, usar **tabla ordenada por ratio**.

### 5. Consulta SQL

```sql
SELECT
    e.nombre AS empleado,
    e.puesto,
    t.nombre AS tienda,
    e.salario,
    ROUND(
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2
    ) AS ingresos_generados,
    ROUND(
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)) /
        NULLIF(e.salario, 0),
        2
    ) AS roi_compensacion
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
INNER JOIN pedido p ON p.id_empleado = e.id_empleado
    AND p.estado = 'completado'
INNER JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
WHERE e.activo = TRUE
GROUP BY e.id_empleado, e.nombre, e.puesto, e.salario, t.nombre
ORDER BY roi_compensacion DESC;
```

**Metabase:**
- Tipo: Tabla o Scatter
- Si tabla: ordenar por `roi_compensacion` DESC

---

## 5 — Distribución salarial por rango (bandas)

### 1. Nombre del indicador

Distribución del personal activo por banda salarial

### 2. Qué representa en términos de negocio

Clasificación de empleados activos en tramos de salario, mostrando cuántas personas se encuentran en cada banda.

### 3. Por qué es importante para el área

Evidencia la concentración salarial e identifica si la mayoría del personal se ubica en la banda más baja (posible riesgo de retención). Apoya el diseño de estructuras de compensación más equitativas y la planificación de ajustes por niveles.

### 4. Visualización

**Bar chart ordenado por banda:** las barras muestran la frecuencia de cada tramo; el orden ascendente de los rangos permite leer la forma de la distribución salarial de la empresa.

### 5. Consulta SQL

```sql
SELECT
    CASE
        WHEN salario < 3000                THEN '1. Menos de 3,000'
        WHEN salario BETWEEN 3000 AND 4999 THEN '2. 3,000 – 4,999'
        WHEN salario BETWEEN 5000 AND 7999 THEN '3. 5,000 – 7,999'
        ELSE                                    '4. 8,000 o más'
    END AS banda_salarial,
    COUNT(*) AS cantidad_empleados
FROM empleado
WHERE activo = TRUE
GROUP BY banda_salarial
ORDER BY banda_salarial;
```

**Metabase:**
- Eje X = `banda_salarial`
- Eje Y = `cantidad_empleados`

---

## 6 — Porcentaje del costo de nómina por puesto

### 1. Nombre del indicador

Participación de cada puesto en el costo total de nómina (%)

### 2. Qué representa en términos de negocio

Cuánto representa la masa salarial de cada rol (Vendedor, Cajero, Supervisor, etc.) sobre el total de la nómina mensual de personal activo.

### 3. Por qué es importante para el área

Permite identificar qué roles concentran el gasto en compensaciones y evaluar si esa distribución es coherente con la estrategia operativa (p. ej. si Gerentes consumen una proporción desproporcionada respecto a la fuerza de ventas directa).

### 4. Visualización

**Pie chart:** la participación porcentual de partes sobre un todo es la representación canónica del gráfico de pastel; con 5-6 puestos es fácil de leer.

### 5. Consulta SQL

```sql
SELECT
    puesto,
    ROUND(SUM(salario), 2) AS masa_salarial,
    ROUND(100.0 * SUM(salario) / SUM(SUM(salario)) OVER (), 1) AS pct_nomina
FROM empleado
WHERE activo = TRUE
GROUP BY puesto
ORDER BY pct_nomina DESC;
```

**Metabase:**
- Dimensión = `puesto`
- Métrica = `pct_nomina`

---

## 7 — Salario promedio vs. ingresos promedio generados por puesto

### 1. Nombre del indicador

Comparativa salario promedio vs. ingresos promedio generados por puesto

### 2. Qué representa en términos de negocio

Para cada tipo de puesto, muestra lado a lado el salario mensual promedio que se paga y el promedio de ventas que genera cada empleado de ese rol. Expone qué puestos tienen mayor o menor apalancamiento comercial.

### 3. Por qué es importante para el área

Permite cuestionar la estructura de compensación con datos: si los Vendedores generan proporcionalmente menos que los Asesores de Ventas pero ganan lo mismo, hay una oportunidad de rediseño de roles. También justifica diferencias salariales ante dirección con evidencia objetiva.

### 4. Visualización

**Bar chart agrupado (grouped bars):** dos barras por puesto (salario promedio en color A, ingresos promedio en color B) permiten comparar magnitudes y brechas de un vistazo. Configurar en Metabase como chart con dos métricas y `puesto` como dimensión.

### 5. Consulta SQL

```sql
SELECT
    e.puesto,
    ROUND(AVG(e.salario), 2) AS salario_promedio,
    ROUND(
        AVG(ventas.total_ventas), 2
    ) AS ingresos_promedio_generados
FROM empleado e
INNER JOIN (
    SELECT
        p.id_empleado,
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)) AS total_ventas
    FROM pedido p
    INNER JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
    WHERE p.estado = 'completado'
    GROUP BY p.id_empleado
) ventas ON ventas.id_empleado = e.id_empleado
WHERE e.activo = TRUE
GROUP BY e.puesto
ORDER BY ingresos_promedio_generados DESC;
```

**Metabase:**
- Dimensión = `puesto`
- Métricas = `salario_promedio` y `ingresos_promedio_generados`
- Tipo = Bar chart agrupado

---

## 8 — Evolución mensual del ratio nómina / ingresos (últimos 12 meses)

### 1. Nombre del indicador

Tendencia del ratio nómina / ingresos por mes (últimos 12 meses)

### 2. Qué representa en términos de negocio

Cómo ha evolucionado la eficiencia del gasto en personal mes a mes: si el ratio sube, los ingresos crecen más lento que la nómina (o la nómina creció sin respaldo en ventas); si baja, la operación se está volviendo más eficiente.

### 3. Por qué es importante para el área

Conecta RH con la realidad financiera del negocio en el tiempo. Una tendencia al alza sostenida es una señal de alerta temprana que RH puede llevar a dirección antes de que Finanzas lo detecte como problema de margen.

### 4. Visualización

**Línea (Line chart):** la serie temporal muestra la tendencia y puntos de inflexión con claridad; ideal para detectar meses atípicos (campañas, aperturas, temporadas altas).

### 5. Consulta SQL

```sql
SELECT
    DATE_TRUNC('month', p.fecha)::date AS mes,
    ROUND(SUM(e_nomina.nomina_tienda), 2) AS nomina_estimada,
    ROUND(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2) AS ingresos_mes,
    ROUND(
        SUM(e_nomina.nomina_tienda) /
        NULLIF(SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 0),
        4
    ) AS ratio_nomina_ingresos
FROM pedido p
INNER JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
INNER JOIN (
    SELECT id_tienda, SUM(salario) AS nomina_tienda
    FROM empleado
    WHERE activo = TRUE
    GROUP BY id_tienda
) e_nomina ON e_nomina.id_tienda = p.id_tienda
WHERE p.estado = 'completado'
  AND p.fecha >= (CURRENT_DATE - INTERVAL '12 months')
GROUP BY DATE_TRUNC('month', p.fecha)
ORDER BY mes;
```

**Metabase:**
- Eje X = `mes` (como fecha)
- Eje Y = `ratio_nomina_ingresos`

---

## Resumen

| #   | Indicador                                              | Tipo de visualización     |
| --- | ------------------------------------------------------ | ------------------------- |
| 1   | Costo total de nómina mensual                          | Número                    |
| 2   | Ratio nómina / ingresos por tienda                     | Barras horizontales       |
| 3   | Top 15 empleados por ingresos generados                | Barras                    |
| 4   | ROI de compensación por empleado                       | Scatter / Tabla           |
| 5   | Distribución por banda salarial                        | Barras                    |
| 6   | % del costo de nómina por puesto                       | Pie chart                 |
| 7   | Salario promedio vs. ingresos promedio por puesto      | Barras agrupadas          |
| 8   | Tendencia mensual del ratio nómina / ingresos          | Línea                     |

**Tab del dashboard:** `Compensaciones`  
**Base de datos en Metabase:** `RetailMax`