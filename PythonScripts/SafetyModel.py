from scipy import stats as ss
import os
import json
import math
import numpy as np
import heapq

data_path = "./data"
metadata_file_path = os.path.join(data_path, 'grid-metadata.json')
crime_grid_prefix = 'crime-grid'

class SafetyModel:

    def __init__(self, loader):
        self.metadata = loader.load_metadata()
        self.grids = loader.load_grid_files(self.metadata)
        # Safety score will be based off the max # crimes in area
        self.max_of_maxes = max([grid.get_max() for grid in self.grids])

    def in_bounds(self, lat, lon):
        return self.metadata['bot_lat'] <= lat <= self.metadata['top_lat'] and \
               self.metadata['left_lon'] <= lon <= self.metadata['right_lon']

    def get_risk_score_for_location(self, lat, lon, hour):
        if not self.in_bounds(lat, lon):
            return 0

        time_bin = hour // 2 # Each bin maps to 2 hours
        grid = self.grids[time_bin]
        grid_val = grid.get_grid_cell_at(lat, lon)
        risk = self.get_grid_value_risk(grid_val)
        return risk

    def get_path_risk_score(self, waypoints, hour):
        highest_risk = 0
        top_risks = []
        for lat, lon in waypoints:
            risk = self.get_risk_score_for_location(lat, lon, hour)
            highest_risk = max(highest_risk, risk)
            if not len(top_risks) or risk > min(top_risks):
                if len(top_risks) < 3:
                    heapq.heappush(top_risks, risk)
                else:
                    heapq.heappushpop(top_risks, risk)
        final_risk = highest_risk
        if len(top_risks) == 3:
            final_risk += (1 - final_risk) * np.mean(top_risks)
        return final_risk

    def get_grid_value_risk(self, grid_val):
        grid_val /= self.max_of_maxes # 0 to 1
        # Based off the cdf of Beta(7,8), normalizes outputs to 0 to 1
        return self.beta_risk(grid_val)

    def beta_risk(self, normalized_score):
        risk = ss.beta.cdf(normalized_score, 7, 8, 0, 1)
        return risk


class FileLoader():

    def load_metadata(self):
        with open(metadata_file_path) as json_file:
            metadata = json.load(json_file)
        return metadata

    def load_grid_files(self, metadata):
        grids = []
        for file in os.listdir(data_path):
            if file.startswith(crime_grid_prefix):
                with open(os.path.join(data_path, file)) as json_file:
                    bins = json.load(json_file)
                    grid = Grid(bins, metadata)
                    grids.append(grid)
        return grids


class Grid:

    def __init__(self, data, metadata):
        self.bins = data
        self.start_lon = metadata['left_lon']
        self.start_lat = metadata['top_lat']
        self.end_lon = metadata['right_lon']
        self.end_lat = metadata['bot_lat']
        self.boxes_x = metadata['num_x_boxes']
        self.boxes_y = metadata['num_y_boxes']
        self.height = self.start_lat - self.end_lat
        self.width = self.end_lon - self.start_lon

    def get_max(self):
        return np.max(self.bins)

    def get_grid_cell_at(self, lat, lon):
        scaled_lat = (self.start_lat - lat) / self.height
        scaled_lon = (lon - self.start_lon) / self.width
        loc_x = min(self.boxes_x - 1, math.floor(scaled_lon * self.boxes_x))
        loc_y = min(self.boxes_y - 1, math.floor(scaled_lat * self.boxes_y))
        return self.bins[loc_y][loc_x]