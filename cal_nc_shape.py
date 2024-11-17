import xarray as xr
import numpy as np

# 情况A - 规则网格，只有中心点坐标
ds = xr.Dataset(
    coords={
        'lat': np.arange(32, 35, 0.5)+0.25,
        'lon': np.arange(115, 120, 0.5)+0.25
    }
)

# 情况B - 不规则网格，有2D的经纬度查找表
lon_2d, lat_2d = np.meshgrid(np.arange(115, 120, 0.5)+np.arange(0.0, 0.1, 0.01), 
                             np.arange(32, 35, 0.5)-np.arange(0.0, 0.06, 0.01), 
                             indexing='xy')
ds = xr.Dataset(
    coords={
        'latitude': (('y', 'x'), lat_2d),
        'longitude': (('y', 'x'), lon_2d)
    }
)

# 情况C - 提供了边界点
ny, nx = 6, 10  # 6x10的网格
lat_bounds = np.zeros((ny, nx, 4))  # 4个顶点
lon_bounds = np.zeros((ny, nx, 4))

# 基础网格范围
lat_base = np.linspace(32, 35, ny+1)  # 包含边界点
lon_base = np.linspace(115, 120, nx+1)

# 为每个格点生成4个顶点坐标
for i in range(ny):
    for j in range(nx):
        # 逆时针顺序的4个顶点
        lat_bounds[i,j] = [lat_base[i], lat_base[i], lat_base[i+1], lat_base[i+1]]
        lon_bounds[i,j] = [lon_base[j], lon_base[j+1], lon_base[j+1], lon_base[j]]

ds = xr.Dataset({
    'lat_bounds': (('y', 'x', 'vertices'), lat_bounds),
    'lon_bounds': (('y', 'x', 'vertices'), lon_bounds)
})