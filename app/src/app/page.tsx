export default function Home() {
  return (
    <main className="min-h-screen bg-gray-950 text-white flex flex-col items-center justify-center px-6">
      <div className="max-w-2xl w-full text-center space-y-8">

        {/* Badge */}
        <span className="inline-block px-3 py-1 text-xs font-semibold tracking-widest uppercase bg-emerald-500/10 text-emerald-400 rounded-full border border-emerald-500/20">
          Production Ready
        </span>

        {/* Heading */}
        <h1 className="text-5xl font-bold tracking-tight">
          Next.js on{" "}
          <span className="text-emerald-400">AWS Fargate</span>
        </h1>

        <p className="text-gray-400 text-lg leading-relaxed">
          This app is running in a Docker container on ECS Fargate, deployed
          automatically via GitHub Actions, and served behind CloudFront + ALB.
        </p>

        {/* Stack badges */}
        <div className="flex flex-wrap justify-center gap-2 pt-2">
          {[
            "Next.js 14",
            "ECS Fargate",
            "Terraform",
            "GitHub Actions",
            "CloudFront",
            "API Gateway",
            "RDS Postgres",
          ].map((tech) => (
            <span
              key={tech}
              className="px-3 py-1 text-sm bg-white/5 border border-white/10 rounded-md text-gray-300"
            >
              {tech}
            </span>
          ))}
        </div>

        {/* Health check link */}
        <div className="pt-4">
          <a
            href="/api/health"
            className="inline-flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-400 transition-colors text-gray-950 font-semibold rounded-lg text-sm"
          >
            Check Health Endpoint →
          </a>
        </div>

        <p className="text-gray-600 text-sm">
          Edit{" "}
          <code className="text-gray-400 bg-white/5 px-1.5 py-0.5 rounded">
            app/src/app/page.tsx
          </code>{" "}
          to start building your app.
        </p>
      </div>
    </main>
  );
}