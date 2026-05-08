
import os
import glob
import numpy as np
import pandas as pd

DATA_DIR = "data/dataverse_files"
OUTDIR = "data/datasets"

# Compute or load packing metrics for every state × decade
def compute_metrics_for_file(path):
    """
    Load a *_stats.csv, separate enacted from simulated plans, and return a
    dict of packing metrics for the enacted plan relative to the simulation
    distribution.
    """
    fname  = os.path.basename(path)
    parts  = fname.split("_")
    state  = parts[0]
    decade = parts[2]                            # "2010" or "2020"
    enacted_label = f"cd_{decade}"

    df = pd.read_csv(path, low_memory=False)

    enacted   = df[df["draw"] == enacted_label]
    simulated = df[df["draw"] != enacted_label]

    if enacted.empty or simulated.empty:
        return None

    # egap and e_dem are plan-level constants repeated per district row
    enacted_egap  = pd.to_numeric(enacted["egap"],  errors="coerce").iloc[0]
    enacted_edem  = pd.to_numeric(enacted["e_dem"], errors="coerce").iloc[0]
    enacted_pbias = pd.to_numeric(enacted["pbias"], errors="coerce").iloc[0]

    sim_egap  = simulated.groupby("draw")["egap"].first().astype(float)
    sim_edem  = simulated.groupby("draw")["e_dem"].first().astype(float)

    sim_egap_mean = sim_egap.mean()
    sim_egap_std  = sim_egap.std()
    egap_zscore   = (enacted_egap - sim_egap_mean) / sim_egap_std if sim_egap_std > 0 else np.nan
    egap_pct      = float((sim_egap < enacted_egap).mean() * 100)

    # Max Black VAP concentration
    simulated = simulated.copy()
    simulated["bvap_share"] = pd.to_numeric(simulated["vap_black"], errors="coerce") / \
                              pd.to_numeric(simulated["total_vap"],  errors="coerce")
    enacted_bvap = pd.to_numeric(enacted["vap_black"], errors="coerce") / \
                   pd.to_numeric(enacted["total_vap"],  errors="coerce")

    max_bvap_enacted = enacted_bvap.max()
    sim_max_bvap     = simulated.groupby("draw")["bvap_share"].max().astype(float)
    bvap_zscore      = (max_bvap_enacted - sim_max_bvap.mean()) / sim_max_bvap.std() \
                        if sim_max_bvap.std() > 0 else np.nan
    bvap_pct         = float((sim_max_bvap < max_bvap_enacted).mean() * 100)

    return {
        "state":          state,
        "decade":         decade,
        "n_districts":    len(enacted),
        "n_simulations":  len(sim_egap),
        "enacted_egap":   enacted_egap,
        "sim_egap_mean":  sim_egap_mean,
        "sim_egap_std":   sim_egap_std,
        "egap_zscore":    egap_zscore,
        "egap_pct":       egap_pct,
        "enacted_edem":   enacted_edem,
        "sim_edem_mean":  sim_edem.mean(),
        "enacted_pbias":  enacted_pbias,
        "max_bvap":       max_bvap_enacted,
        "sim_max_bvap_mean": sim_max_bvap.mean(),
        "bvap_zscore":    bvap_zscore,
        "bvap_pct":       bvap_pct,
    }


if os.path.exists(OUTDIR):
    print(f"Loading OUTDIRd metrics from {OUTDIR}")
    metrics_df = pd.read_csv(OUTDIR)
else:
    print("Computing packing metrics for all state × decade combinations...")
    all_paths = sorted(
        glob.glob(os.path.join(DATA_DIR, "*_cd_2010", "*_cd_2010_stats.csv")) +
        glob.glob(os.path.join(DATA_DIR, "*_cd_2020", "*_cd_2020_stats.csv"))
    )
    print(f"  Found {len(all_paths)} stats files")
    records = []
    for i, path in enumerate(all_paths):
        state_decade = os.path.basename(path).replace("_stats.csv", "")
        print(f"  [{i+1}/{len(all_paths)}] {state_decade}", end="\r")
        row = compute_metrics_for_file(path)
        if row:
            records.append(row)
    print()
    metrics_df = pd.DataFrame(records)
    metrics_df.to_csv(OUTDIR, index=False)
    print(f"Saved metrics OUTDIR → {OUTDIR}")