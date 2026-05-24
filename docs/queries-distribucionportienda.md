# Tab `Distribución por Tienda` — Recursos Humanos `RetailMax`

Dashboard de Metabase · Área: Recursos Humanos  
Enfoque del tab: análisis de la distribución geográfica y operativa del personal, cobertura por sucursal, carga de trabajo por tienda y eficiencia de dotación en el punto de venta.

---

## 1 — Headcount activo por tienda

### 1. Nombre del indicador

Headcount activo por tienda

### 2. Qué representa en términos de negocio

Número de empleados activos asignados a cada sucursal RetailMax en este momento. Muestra cómo se distribuye la fuerza laboral disponible a lo largo de la red de tiendas.

### 3. Por qué es importante para el área

Es el punto de partida para cualquier análisis de dotación: sin saber cuántas personas tiene cada tienda, no se pueden tomar decisiones de traslado, contratación focalizada o reestructuración. Identifica de inmediato sucursales con déficit o exceso de personal respecto al promedio de la red.

### 4. Visualización

**Bar chart ordenado de mayor a menor:** permite comparar todas las tiendas en un solo vistazo y priorizar acciones donde la brecha respecto al promedio es más pronunciada.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    COUNT(e.id_empleado) AS headcount_activo
FROM tienda t
LEFT JOIN empleado e ON e.id_tienda = t.id_tienda
    AND e.activo = TRUE
GROUP BY t.id_tienda, t.nombre
ORDER BY headcount_activo DESC;
```

**Metabase:**
- Eje X = `tienda`
- Eje Y = `headcount_activo`

---

## 2 — Composición de puestos por tienda

### 1. Nombre del indicador

Distribución de puestos por tienda (estructura de roles en cada sucursal)

### 2. Qué representa en términos de negocio

Para cada tienda, muestra cuántos empleados activos ocupa cada tipo de puesto (Vendedor, Cajero, Supervisor, Gerente de Tienda, Bodeguero, Asesor de Ventas). Refleja la mezcla de roles disponibles en cada sucursal.

### 3. Por qué es importante para el área

Detecta desbalances en la composición de roles: una tienda con demasiados supervisores y pocos vendedores tiene una estructura operativa ineficiente. También sirve para verificar que todas las sucursales cuentan con los roles críticos cubiertos (p. ej. al menos un Gerente de Tienda).

### 4. Visualización

**Stacked bar chart:** cada barra representa una tienda y cada segmento un puesto. Permite comparar tanto el headcount total como la mezcla de roles entre sucursales en una sola vista.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    e.puesto,
    COUNT(*) AS cantidad
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
WHERE e.activo = TRUE
GROUP BY t.id_tienda, t.nombre, e.puesto
ORDER BY t.nombre, cantidad DESC;
```

**Metabase:**
- Dimensión = `tienda`
- Segmento de color = `puesto`
- Métrica = `cantidad`
- Tipo = Stacked bar

---

## 3 — Pedidos atendidos por empleado por tienda (carga operativa)

### 1. Nombre del indicador

Promedio de pedidos atendidos por empleado activo, por tienda

### 2. Qué representa en términos de negocio

Cuántos pedidos completados ha gestionado en promedio cada empleado en su tienda. Es un proxy de la carga operativa que enfrenta el personal de cada sucursal.

### 3. Por qué es importante para el área

Una tienda con ratio alto está bajo presión operativa: su personal atiende más pedidos por persona que la media, lo que puede derivar en errores, fatiga o rotación. Una tienda con ratio bajo podría estar sobre-dotada o tener baja demanda. Permite balancear carga y justificar contrataciones adicionales con datos.

### 4. Visualización

**Bar chart horizontal ordenado de mayor a menor:** el ranking de carga por tienda es inmediatamente accionable; las tiendas en el extremo superior son las candidatas a refuerzo de plantilla.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    COUNT(DISTINCT e.id_empleado) AS empleados_activos,
    COUNT(DISTINCT p.id_pedido) AS pedidos_completados,
    ROUND(
        COUNT(DISTINCT p.id_pedido)::numeric /
        NULLIF(COUNT(DISTINCT e.id_empleado), 0),
        1
    ) AS pedidos_por_empleado
FROM tienda t
INNER JOIN empleado e ON e.id_tienda = t.id_tienda
    AND e.activo = TRUE
LEFT JOIN pedido p ON p.id_tienda = t.id_tienda
    AND p.estado = 'completado'
GROUP BY t.id_tienda, t.nombre
ORDER BY pedidos_por_empleado DESC;
```

**Metabase:**
- Eje X = `pedidos_por_empleado`
- Eje Y = `tienda`

---

## 4 — Antigüedad promedio del personal por tienda

### 1. Nombre del indicador

Antigüedad promedio del personal activo por tienda (años)

### 2. Qué representa en términos de negocio

Tiempo medio, en años, que llevan en la empresa los empleados activos de cada sucursal. Refleja la madurez y estabilidad de la plantilla a nivel de tienda.

### 3. Por qué es importante para el área

Tiendas con antigüedad promedio muy baja suelen tener mayor rotación reciente y menor experiencia acumulada, lo que puede afectar la calidad del servicio al cliente. Tiendas con plantilla muy veterana pueden requerir planes de desarrollo o sucesión. Permite segmentar acciones de retención y capacitación por sucursal.

### 4. Visualización

**Bar chart:** comparar la antigüedad entre tiendas en barras verticales permite identificar de un vistazo cuáles sucursales tienen plantillas más nuevas o más maduras.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    ROUND(
        AVG((CURRENT_DATE - e.fecha_contratacion) / 365.25)::numeric,
        1
    ) AS antiguedad_promedio_anios
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
WHERE e.activo = TRUE
GROUP BY t.id_tienda, t.nombre
ORDER BY antiguedad_promedio_anios DESC;
```

**Metabase:**
- Eje X = `tienda`
- Eje Y = `antiguedad_promedio_anios`

---

## 5 — Tiendas sin cobertura en puestos críticos

### 1. Nombre del indicador

Tiendas sin al menos un empleado activo en puestos críticos

### 2. Qué representa en términos de negocio

Identifica qué sucursales carecen de personal activo en roles operativos esenciales: Gerente de Tienda y Supervisor. Una tienda sin estos puestos cubiertos está operando con un riesgo de gobernanza significativo.

### 3. Por qué es importante para el área

Es una alerta temprana de riesgo operativo. Si una tienda no tiene Gerente activo, la cadena de mando y el control operativo están comprometidos. RH puede actuar preventivamente con traslados temporales o contrataciones de emergencia antes de que el problema escale.

### 4. Visualización

**Tabla:** el resultado es una lista de situaciones concretas (tienda + puesto faltante) que requiere lectura exacta para actuar, no comparación de magnitudes. La tabla es la visualización más accionable en este caso.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    puestos_criticos.puesto AS puesto_critico,
    COUNT(e.id_empleado) AS empleados_activos_en_puesto
FROM tienda t
CROSS JOIN (VALUES ('Gerente de Tienda'), ('Supervisor')) AS puestos_criticos(puesto)
LEFT JOIN empleado e ON e.id_tienda = t.id_tienda
    AND e.puesto = puestos_criticos.puesto
    AND e.activo = TRUE
GROUP BY t.id_tienda, t.nombre, puestos_criticos.puesto
HAVING COUNT(e.id_empleado) = 0
ORDER BY t.nombre, puestos_criticos.puesto;
```

**Metabase:**
- Tipo = Tabla
- Columnas visibles = `tienda`, `puesto_critico`

---

## 6 — Ingresos por tienda vs. headcount (eficiencia de dotación)

### 1. Nombre del indicador

Ingresos generados por empleado activo por tienda

### 2. Qué representa en términos de negocio

Cuántos quetzales de ventas netas (pedidos completados, descontados descuentos) genera en promedio cada empleado activo en su tienda. Conecta el tamaño de la plantilla con la productividad comercial de cada sucursal.

### 3. Por qué es importante para el área

Permite comparar eficiencia de dotación entre tiendas con contextos distintos: una tienda con muchos empleados pero pocos ingresos por persona puede estar sobre-dotada o tener problemas de demanda. Una tienda con ingresos por empleado muy altos puede estar subutilizada en headcount. Apoya decisiones de redistribución de personal basadas en productividad real.

### 4. Visualización

**Bar chart ordenado de mayor a menor ratio:** el ranking de productividad por tienda es directo y comparable. Si Metabase lo permite, superponer una línea con el promedio de red para contextualizar cada barra.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    COUNT(DISTINCT e.id_empleado) AS headcount_activo,
    ROUND(
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)), 2
    ) AS ingresos_totales,
    ROUND(
        SUM(dp.cantidad * dp.precio_unitario * (1 - dp.descuento / 100.0)) /
        NULLIF(COUNT(DISTINCT e.id_empleado), 0),
        2
    ) AS ingresos_por_empleado
FROM tienda t
INNER JOIN empleado e ON e.id_tienda = t.id_tienda
    AND e.activo = TRUE
INNER JOIN pedido p ON p.id_tienda = t.id_tienda
    AND p.estado = 'completado'
INNER JOIN detalle_pedido dp ON dp.id_pedido = p.id_pedido
GROUP BY t.id_tienda, t.nombre
ORDER BY ingresos_por_empleado DESC;
```

**Metabase:**
- Eje X = `tienda`
- Eje Y = `ingresos_por_empleado`

---

## 7 — Nuevas contrataciones por tienda (últimos 12 meses)

### 1. Nombre del indicador

Contrataciones recientes por tienda (últimos 12 meses)

### 2. Qué representa en términos de negocio

Cuántos empleados nuevos ha incorporado cada tienda en los últimos 12 meses. Refleja el crecimiento o reposición de plantilla a nivel de sucursal.

### 3. Por qué es importante para el área

Una tienda con muchas contrataciones recientes puede estar en expansión o atravesando alta rotación; ambos escenarios requieren atención de RH (onboarding intensivo o plan de retención). Tiendas con cero contrataciones pueden estar estancadas o haber estabilizado su plantilla. Permite distribuir recursos de inducción y seguimiento a los nuevos ingresos.

### 4. Visualización

**Bar chart:** comparar el volumen de contrataciones recientes entre tiendas es directo en barras; facilita priorizar dónde concentrar esfuerzos de integración.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    COUNT(e.id_empleado) AS contrataciones_recientes
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
WHERE e.fecha_contratacion >= (CURRENT_DATE - INTERVAL '12 months')
GROUP BY t.id_tienda, t.nombre
ORDER BY contrataciones_recientes DESC;
```

**Metabase:**
- Eje X = `tienda`
- Eje Y = `contrataciones_recientes`

---

## 8 — Ratio de rotación estimada por tienda

### 1. Nombre del indicador

Tasa de rotación estimada por tienda (% inactivos sobre total histórico)

### 2. Qué representa en términos de negocio

Proporción de empleados que han salido (inactivos) respecto al total histórico de personal registrado en cada tienda. Sirve como indicador aproximado de rotación acumulada por sucursal.

### 3. Por qué es importante para el área

Tiendas con tasas de rotación elevadas tienen mayor costo oculto (reclutamiento, inducción, curva de aprendizaje) y menor estabilidad operativa. Identificar qué sucursales concentran la rotación permite a RH focalizar investigaciones de clima laboral, revisiones salariales o cambios de liderazgo en los puntos más críticos.

### 4. Visualización

**Bar chart horizontal con formato de porcentaje:** el ranking de rotación por tienda es más legible en barras horizontales cuando los nombres de tienda son largos; el formato % facilita la comparación directa.

### 5. Consulta SQL

```sql
SELECT
    t.nombre AS tienda,
    COUNT(e.id_empleado) AS total_historico,
    SUM(CASE WHEN e.activo = FALSE THEN 1 ELSE 0 END) AS inactivos,
    ROUND(
        100.0 * SUM(CASE WHEN e.activo = FALSE THEN 1 ELSE 0 END) /
        NULLIF(COUNT(e.id_empleado), 0),
        1
    ) AS tasa_rotacion_pct
FROM empleado e
INNER JOIN tienda t ON t.id_tienda = e.id_tienda
GROUP BY t.id_tienda, t.nombre
ORDER BY tasa_rotacion_pct DESC;
```

**Metabase:**
- Eje X = `tasa_rotacion_pct`
- Eje Y = `tienda`

---

## Resumen

| #   | Indicador                                              | Tipo de visualización       |
| --- | ------------------------------------------------------ | --------------------------- |
| 1   | Headcount activo por tienda                            | Barras                      |
| 2   | Composición de puestos por tienda                      | Stacked bar                 |
| 3   | Pedidos por empleado por tienda (carga operativa)      | Barras horizontales         |
| 4   | Antigüedad promedio por tienda                         | Barras                      |
| 5   | Tiendas sin cobertura en puestos críticos              | Tabla                       |
| 6   | Ingresos por empleado activo por tienda                | Barras                      |
| 7   | Contrataciones recientes por tienda (12 meses)         | Barras                      |
| 8   | Tasa de rotación estimada por tienda                   | Barras horizontales         |

**Tab del dashboard:** `Distribución por Tienda`  
**Base de datos en Metabase:** `RetailMax`