"use client";

import { useEffect, useState } from "react";
import { ConnectKitButton } from "connectkit";
import {
  getAllUsers,
  registerUser,
  approveUsdt,
  changeRewardCycle,
  withdrawEmergency,
  sendNewMessage,
  distributeRewards,
  getOwnerMessage,
  getRewardCycleDuration,
  getUserInfo,
} from "../web3/actions";
import { useAccount } from "wagmi";
import { waitForTransactionReceipt } from "wagmi/actions";
import { config } from "../web3/Web3Provider";

const PLAN_OPTIONS = [
  { label: "Binary", value: 0 },
  { label: "InOrder", value: 1 },
];

// Helper function to format addresses
const formatAddress = (address) => {
  if (
    !address ||
    address === "0x0000000000000000000000000000000000000000" ||
    address === "0x0"
  ) {
    return "N/A";
  }
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

export default function Home() {
  const [form, setForm] = useState({
    plan: PLAN_OPTIONS[0].value,
    referrer: "",
  });
  const [loading, setLoading] = useState(false);
  const [registering, setRegistering] = useState(false);
  const [error, setError] = useState("");
  const { isConnected, address } = useAccount();

  const [newRewardCycle, setNewRewardCycle] = useState("");
  const [newMessage, setNewMessage] = useState("");
  const [ownerLoading, setOwnerLoading] = useState(false);

  const owner = "0x6Ac97c57138BD707680A10A798bAf24aCe62Ae9D";
  const admin = "0x81878429C68350DdB41Aaaf05cF2f03bf37e72D5";

  const { data: users } = getAllUsers();
  const { data: rewardCycleDuration } = getRewardCycleDuration();
  const { data: ownerMessage } = getOwnerMessage();
  const { data: currentUser } = getUserInfo(address);

  // Handle form input changes
  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  };

  // Handle registration
  const handleRegister = async (e) => {
    e.preventDefault();
    setRegistering(true);
    setError("");
    try {
      const tx1 = await approveUsdt(100e18);
      await waitForTransactionReceipt(config, { hash: tx1 });
      const tx2 = await registerUser(Number(form.plan), form.referrer, config);
      await waitForTransactionReceipt(config, { hash: tx2 });
      setForm({ plan: PLAN_OPTIONS[0].value, referrer: "" });
    } catch (err) {
      setError(err?.message || "Registration failed");
    }
    setRegistering(false);
  };

  // Owner functions
  const handleChangeRewardCycle = async () => {
    if (!newRewardCycle) return;
    setOwnerLoading(true);
    setError("");
    try {
      const tx = await changeRewardCycle(BigInt(newRewardCycle));
      await waitForTransactionReceipt(config, { hash: tx });
      setNewRewardCycle("");
    } catch (err) {
      setError(err?.message || "Failed to change reward cycle");
    }
    setOwnerLoading(false);
  };

  const handleSendMessage = async () => {
    if (!newMessage) return;
    setOwnerLoading(true);
    setError("");
    try {
      const tx = await sendNewMessage(newMessage);
      await waitForTransactionReceipt(config, { hash: tx });
      setNewMessage("");
    } catch (err) {
      setError(err?.message || "Failed to send message");
    }
    setOwnerLoading(false);
  };

  const handleDistributeRewards = async () => {
    setOwnerLoading(true);
    setError("");
    try {
      const tx = await distributeRewards(config);
      await waitForTransactionReceipt(config, { hash: tx });
    } catch (err) {
      setError(err?.message || "Failed to distribute rewards");
    }
    setOwnerLoading(false);
  };

  const handleEmergencyWithdraw = async () => {
    setOwnerLoading(true);
    setError("");
    try {
      const tx = await withdrawEmergency();
      await waitForTransactionReceipt(config, { hash: tx });
    } catch (err) {
      setError(err?.message || "Failed to withdraw emergency");
    }
    setOwnerLoading(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-100 dark:from-zinc-900 dark:via-zinc-950 dark:to-zinc-900 flex flex-col items-center">
      <ConnectKitButton />
      {/* Header Bar */}
      <header className="w-full py-6 px-4 bg-gradient-to-r from-blue-600 to-purple-600 dark:from-zinc-800 dark:to-zinc-900 shadow-lg flex justify-center items-center mb-10">
        <h1 className="text-3xl sm:text-4xl font-extrabold text-white tracking-tight drop-shadow-lg">
          SmartBinancePlus DApp
        </h1>
      </header>

      <main className="w-full max-w-7xl flex flex-col gap-10 px-4 pb-16">
        {/* Owner Message for All Users */}
        <section className="w-full">
          <div className="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-2xl shadow-2xl p-6 border border-blue-200 dark:border-blue-800 backdrop-blur-md">
            <h2 className="text-xl font-bold mb-3 text-blue-700 dark:text-blue-300 flex items-center gap-2">
              <span>📢</span>
              Owner Message
            </h2>
            <p className="text-blue-900 dark:text-blue-100 text-lg">
              {ownerMessage ? ownerMessage : "No message from owner yet."}
            </p>
          </div>
        </section>

        {/* Current User Info */}
        {isConnected && address && (
          <section className="w-full">
            <div className="bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-2xl shadow-2xl p-6 border border-green-200 dark:border-green-800 backdrop-blur-md">
              <h2 className="text-xl font-bold mb-4 text-green-700 dark:text-green-300 flex items-center gap-2">
                <span>👤</span>
                My Profile
              </h2>
              {currentUser ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      My Address
                    </h3>
                    <p className="font-mono text-xs break-all text-green-900 dark:text-green-100">
                      {formatAddress(address)}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Plan
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {PLAN_OPTIONS[currentUser.plan]?.label ||
                        currentUser.plan}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Total Earnings
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.totalEarnings?.toString?.() ??
                        currentUser.totalEarnings}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Directs
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.directs}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Balance Points
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.balancePoints}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Status
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.active ? (
                        <span className="inline-block px-2 py-0.5 rounded bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-200 text-xs font-semibold">
                          Active
                        </span>
                      ) : (
                        <span className="inline-block px-2 py-0.5 rounded bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-200 text-xs font-semibold">
                          Inactive
                        </span>
                      )}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Referrer
                    </h3>
                    <p className="font-mono text-xs break-all text-green-900 dark:text-green-100">
                      {formatAddress(currentUser.referrer)}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Left Leg
                    </h3>
                    <p className="font-mono text-xs break-all text-green-900 dark:text-green-100">
                      {formatAddress(currentUser.left)}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Right Leg
                    </h3>
                    <p className="font-mono text-xs break-all text-green-900 dark:text-green-100">
                      {formatAddress(currentUser.right)}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Current Left Volume
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.currentLeftVolume}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Current Right Volume
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.currentRightVolume}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Total Left Volume
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.totalLeftVolume}
                    </p>
                  </div>
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-3">
                    <h3 className="font-semibold text-green-700 dark:text-green-300 mb-1 text-sm">
                      Total Right Volume
                    </h3>
                    <p className="text-green-900 dark:text-green-100">
                      {currentUser.totalRightVolume}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8 text-green-600 dark:text-green-300 font-semibold">
                  Loading your profile...
                </div>
              )}
            </div>
          </section>
        )}

        {/* Owner/Admin Sections */}
        {(address == owner || address == admin) && (
          <section className="w-full">
            <div className="bg-gradient-to-r from-yellow-50 to-orange-50 dark:from-yellow-900/20 dark:to-orange-900/20 rounded-2xl shadow-2xl p-8 border border-yellow-200 dark:border-yellow-800 backdrop-blur-md">
              <h2 className="text-2xl font-bold mb-6 text-yellow-700 dark:text-yellow-300 flex items-center gap-2">
                <span>👑</span>
                {address == owner ? "Owner" : "Admin"} Dashboard
              </h2>

              {/* Current Info */}
              <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-4 mb-6">
                <h3 className="font-semibold text-yellow-700 dark:text-yellow-300 mb-2">
                  Current Reward Cycle
                </h3>
                <p className="text-lg font-mono">
                  {rewardCycleDuration
                    ? `${Number(rewardCycleDuration)} seconds`
                    : "Loading..."}
                </p>
              </div>

              {/* Owner/Admin Actions */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Change Reward Cycle - Available for both Owner and Admin */}
                <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-4">
                  <h3 className="font-semibold text-yellow-700 dark:text-yellow-300 mb-3">
                    Change Reward Cycle
                  </h3>
                  <div className="space-y-3">
                    <input
                      type="number"
                      value={newRewardCycle}
                      onChange={(e) => setNewRewardCycle(e.target.value)}
                      placeholder="New cycle duration (seconds)"
                      className="w-full border border-yellow-300 dark:border-yellow-700 rounded-lg px-3 py-2 bg-white/50 dark:bg-zinc-800/50 text-zinc-900 dark:text-zinc-100"
                      disabled={ownerLoading}
                    />
                    <button
                      onClick={handleChangeRewardCycle}
                      disabled={ownerLoading || !newRewardCycle}
                      className="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-2 rounded-lg transition disabled:opacity-50"
                    >
                      {ownerLoading ? "Updating..." : "Update Cycle"}
                    </button>
                  </div>
                </div>

                {/* Emergency Withdraw - Available for both Owner and Admin */}
                <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-4">
                  <h3 className="font-semibold text-yellow-700 dark:text-yellow-300 mb-3">
                    Emergency Withdraw
                  </h3>
                  <button
                    onClick={handleEmergencyWithdraw}
                    disabled={ownerLoading}
                    className="w-full bg-red-600 hover:bg-red-700 text-white font-bold py-2 rounded-lg transition disabled:opacity-50"
                  >
                    {ownerLoading ? "Withdrawing..." : "Emergency Withdraw"}
                  </button>
                </div>

                {/* Send Message - Owner Only */}
                {address == owner && (
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-4">
                    <h3 className="font-semibold text-yellow-700 dark:text-yellow-300 mb-3">
                      Send Message
                    </h3>
                    <div className="space-y-3">
                      <input
                        type="text"
                        value={newMessage}
                        onChange={(e) => setNewMessage(e.target.value)}
                        placeholder="New owner message"
                        className="w-full border border-yellow-300 dark:border-yellow-700 rounded-lg px-3 py-2 bg-white/50 dark:bg-zinc-800/50 text-zinc-900 dark:text-zinc-100"
                        disabled={ownerLoading}
                      />
                      <button
                        onClick={handleSendMessage}
                        disabled={ownerLoading || !newMessage}
                        className="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-bold py-2 rounded-lg transition disabled:opacity-50"
                      >
                        {ownerLoading ? "Sending..." : "Send Message"}
                      </button>
                    </div>
                  </div>
                )}

                {/* Distribute Rewards - Owner Only */}
                {address == owner && (
                  <div className="bg-white/50 dark:bg-zinc-800/50 rounded-lg p-4">
                    <h3 className="font-semibold text-yellow-700 dark:text-yellow-300 mb-3">
                      Distribute Rewards
                    </h3>
                    <button
                      onClick={handleDistributeRewards}
                      disabled={ownerLoading}
                      className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-2 rounded-lg transition disabled:opacity-50"
                    >
                      {ownerLoading ? "Distributing..." : "Distribute Rewards"}
                    </button>
                  </div>
                )}
              </div>
            </div>
          </section>
        )}

        {/* Registration Card */}
        <section className="w-full max-w-md mx-auto mb-10">
          <div className="bg-white/90 dark:bg-zinc-900/90 rounded-2xl shadow-2xl p-8 border border-zinc-200 dark:border-zinc-800 backdrop-blur-md">
            <h2 className="text-2xl font-bold mb-6 text-blue-700 dark:text-purple-300">
              Register
            </h2>
            {!isConnected && (
              <div className="mb-4 text-red-500">
                Connect your wallet to register
              </div>
            )}
            {error && <div className="mb-4 text-red-500">{error}</div>}
            <form className="space-y-6" onSubmit={handleRegister}>
              <div>
                <label
                  htmlFor="plan"
                  className="block text-sm font-semibold mb-1 text-zinc-700 dark:text-zinc-200"
                >
                  Plan
                </label>
                <select
                  id="plan"
                  name="plan"
                  value={form.plan}
                  onChange={handleChange}
                  className="w-full border border-zinc-300 dark:border-zinc-700 rounded-lg px-4 py-2 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:ring-2 focus:ring-blue-400 dark:focus:ring-purple-500 outline-none transition"
                  disabled={!isConnected || registering}
                >
                  {PLAN_OPTIONS.map((opt) => (
                    <option key={opt.value} value={opt.value}>
                      {opt.label}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label
                  htmlFor="referrer"
                  className="block text-sm font-semibold mb-1 text-zinc-700 dark:text-zinc-200"
                >
                  Referrer Address
                </label>
                <input
                  id="referrer"
                  name="referrer"
                  type="text"
                  value={form.referrer}
                  onChange={handleChange}
                  className="w-full border border-zinc-300 dark:border-zinc-700 rounded-lg px-4 py-2 bg-zinc-50 dark:bg-zinc-800 text-zinc-900 dark:text-zinc-100 focus:ring-2 focus:ring-blue-400 dark:focus:ring-purple-500 outline-none transition font-mono"
                  required
                  placeholder="0x..."
                  disabled={!isConnected || registering}
                />
              </div>
              <button
                type="submit"
                className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 text-white font-bold py-2.5 rounded-lg shadow-md transition text-lg disabled:opacity-60"
                disabled={!isConnected || registering}
              >
                {registering ? "Registering..." : "Register"}
              </button>
            </form>
          </div>
        </section>

        {/* Users Table Card */}
        <section className="w-full">
          <div className="bg-white/90 dark:bg-zinc-900/90 rounded-2xl shadow-2xl p-8 border border-zinc-200 dark:border-zinc-800 backdrop-blur-md">
            <h2 className="text-2xl font-bold mb-6 text-blue-700 dark:text-purple-300">
              All Users
            </h2>
            {loading ? (
              <div className="py-8 text-center text-blue-600 dark:text-purple-300 font-semibold">
                Loading users...
              </div>
            ) : (
              <div className="overflow-x-auto rounded-lg border border-zinc-100 dark:border-zinc-800">
                <table className="min-w-full text-xs sm:text-sm md:text-base border-separate border-spacing-y-1">
                  <thead>
                    <tr className="bg-gradient-to-r from-blue-100 to-purple-100 dark:from-zinc-800 dark:to-zinc-900 text-blue-900 dark:text-purple-200">
                      <th className="px-3 py-2 font-semibold">User Address</th>
                      <th className="px-3 py-2 font-semibold">Referrer</th>
                      <th className="px-3 py-2 font-semibold">Plan</th>
                      <th className="px-3 py-2 font-semibold">
                        Total Earnings
                      </th>
                      <th className="px-3 py-2 font-semibold">Directs</th>
                      <th className="px-3 py-2 font-semibold">Left</th>
                      <th className="px-3 py-2 font-semibold">Right</th>
                      <th className="px-3 py-2 font-semibold">
                        Current Left Vol
                      </th>
                      <th className="px-3 py-2 font-semibold">
                        Current Right Vol
                      </th>
                      <th className="px-3 py-2 font-semibold">
                        Total Left Vol
                      </th>
                      <th className="px-3 py-2 font-semibold">
                        Total Right Vol
                      </th>
                      <th className="px-3 py-2 font-semibold">
                        Balance Points
                      </th>
                      <th className="px-3 py-2 font-semibold">Active</th>
                    </tr>
                  </thead>
                  <tbody>
                    {users?.length === 0 ? (
                      <tr>
                        <td
                          colSpan={13}
                          className="text-center py-6 text-zinc-400 font-medium"
                        >
                          No users registered yet.
                        </td>
                      </tr>
                    ) : (
                      users?.map((user, idx) => (
                        <tr
                          key={idx}
                          className="even:bg-blue-50 even:dark:bg-zinc-800 hover:bg-blue-100 hover:dark:bg-zinc-800/70 transition"
                        >
                          <td className="px-3 py-2 font-mono text-xs sm:text-sm break-all text-blue-900 dark:text-purple-200">
                            {formatAddress(user.userAddress)}
                          </td>
                          <td className="px-3 py-2 font-mono text-xs sm:text-sm break-all text-blue-900 dark:text-purple-200">
                            {formatAddress(user.referrer)}
                          </td>
                          <td className="px-3 py-2">
                            {PLAN_OPTIONS[user.plan]?.label || user.plan}
                          </td>
                          <td className="px-3 py-2">
                            {user.totalEarnings?.toString?.() ??
                              user.totalEarnings}
                          </td>
                          <td className="px-3 py-2">{user.directs}</td>
                          <td className="px-3 py-2 font-mono text-xs sm:text-sm break-all">
                            {formatAddress(user.left)}
                          </td>
                          <td className="px-3 py-2 font-mono text-xs sm:text-sm break-all">
                            {formatAddress(user.right)}
                          </td>
                          <td className="px-3 py-2">
                            {user.currentLeftVolume}
                          </td>
                          <td className="px-3 py-2">
                            {user.currentRightVolume}
                          </td>
                          <td className="px-3 py-2">{user.totalLeftVolume}</td>
                          <td className="px-3 py-2">{user.totalRightVolume}</td>
                          <td className="px-3 py-2">{user.balancePoints}</td>
                          <td className="px-3 py-2">
                            {user.active ? (
                              <span className="inline-block px-2 py-0.5 rounded bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-200 text-xs font-semibold">
                                Yes
                              </span>
                            ) : (
                              <span className="inline-block px-2 py-0.5 rounded bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-200 text-xs font-semibold">
                                No
                              </span>
                            )}
                          </td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </section>
      </main>
    </div>
  );
}
